package ghprofiles

import scala.slick.session.Database
import Database.threadLocalSession
import scala.slick.jdbc.{StaticQuery => Q}
import scala.concurrent._
import scala.Some
import org.json4s.JsonDSL._
import org.json4s._
import org.json4s.native.JsonMethods._
import java.security.MessageDigest
import scala.async.Async.{async, await}
import scala.collection.parallel.immutable.ParSeq
import scala.collection.JavaConverters._
import org.apache.http.impl.client.HttpClients
import org.apache.http.client.methods.HttpGet
import java.io.InputStream
import scala.io.Source
import java.util.concurrent.{Executors, ConcurrentHashMap}
import scala.util.control.Exception._
import scala.util.matching.Regex
import scala.collection.immutable.ListMap


trait GHDataExtraction {

  val executorService = Executors.newFixedThreadPool(Runtime.getRuntime.availableProcessors() * 2)
  implicit val executionContext = ExecutionContext.fromExecutorService(executorService)

  def projectLibsFile = "projectLibs.json"

  def db: Database

  lazy val conn = db

  def printErr(x: String) = System.err.println(x)

  lazy val projectLibs = {
    try {
      val data = Source.fromFile(projectLibsFile).mkString
      val json = parse(data)
      val jsonMap = json.values.asInstanceOf[Map[String, List[String]]]
      printErr("Loading cached data...")
      jsonMap.foldLeft(new ConcurrentHashMap[String, Future[Seq[String]]]().asScala) {
        (acc, x) => acc.putIfAbsent(x._1, Future(x._2.toSeq)); acc
      }
    } catch {
      case e: Exception => new ConcurrentHashMap[String, Future[Seq[String]]]().asScala
    }
  }

  def users(limit: Option[Int] = None): List[String] = {
    val q = limit match {
      case Some(x) => "select login from users where not login regexp '^[A-Z]{8}$' limit " + x
      case None => "select login from users where not login regexp '^[A-Z]{8}$'"
    }

    db withSession {
      Q.queryNA[String](q).list
    }
  }

  def usersWithEmailsHashed(): ParSeq[(String, String, String, String)] = {
    val q = "select login,email,name from users where not login regexp '^[A-Z]{8}$' and email is not null and email != ''"

    conn withSession {
      Q.queryNA[(String, String, String)](q).list.par.map {
        x => (x._1, toMD5(x._2), x._2.toLowerCase, x._3)
      }
    }
  }

  def toMD5(s: String) : String =
    MessageDigest.getInstance("MD5").digest(s.toLowerCase.getBytes).map("%02X".format(_)).mkString.toLowerCase

  def emailHash(login: String): Future[String] = future {
    val q = "select email from users where login = ?"
    conn withSession {
      Q.query[String, String](q).list(login).map { x => toMD5(x) }.head
    }
  }

  def projects(login: String, to: Int): Future[List[Project]] = future {
    val q = s"""select u.login, p.name, p.language
                from users u, projects p, project_commits pc, commits c, users u1
                where u.id = p.owner_id
                and pc.commit_id = c.id
                and pc.project_id = p.id
                and c.author_id = u1.id
                and p.forked_from is null
                and c.created_at < from_unixtime(?)
                and u1.login = ?
                group by u.login, p.name"""

    conn withSession {
      Q.query[(Int, String), (String, String, String)](q).list(to, login)
    } map {
      result => Project(result._1, result._2, result._3)
    }
  }

  def performance(login: String, to: Int): Future[List[WorkHour]] = future {
    val q = s"""select hour(c.created_at) as hour, count(*) as commits
                from projects p, project_commits pc, commits c, users u
                where pc.commit_id = c.id
                and pc.project_id = p.id
                and c.author_id = u.id
                and p.forked_from is null
                and c.created_at < from_unixtime(?)
                and u.login = ?
                group by hour(c.created_at)"""
    conn withSession {
        Q.query[(Int, String), (Int, Int)](q).list(to, login)
    } map {
      result => WorkHour(result._1, result._2)
    }
  }

  def numQuery(q: String, login: String, to: Int = (System.currentTimeMillis() / 1000).toInt): Future[Int] = future {
    conn withSession { Q.query[(Int, String), Int](q).list((to, login)) }.head
  }

  def numFollowers(login: String, to: Int): Future[Int] =  {
    val q = s"""select count(*)
                from followers f, users u
                where f.user_id = u.id
                and f.created_at < from_unixtime(?)
                and u.login = ?"""
    numQuery(q, login, to)
  }

  def numWatchers(login: String, to: Int): Future[Int] =  {
    val q = s"""select count(*)
                from projects p, users u, watchers w
                where p.owner_id = u.id
                and w.repo_id = p.id
                and w.created_at < from_unixtime(?)
                and u.login = ?"""
    numQuery(q, login, to)
  }

  def numPullreqs(login: String, to: Int): Future[Int] =  {
    val q = s"""select count(*)
                from users u, pull_requests pr, pull_request_history prh
                where pr.id = prh.pull_request_id
                and prh.actor_id = u.id
                and prh.action = 'opened'
                and prh.created_at < from_unixtime(?)
                and u.login = ?"""
    numQuery(q, login, to)
  }

  def numIssues(login: String, to: Int): Future[Int] =  {
    val q = s"""select count(*)
                from users u, issues i
                where i.reporter_id = u.id
                and i.pull_request_id is null
                and i.created_at < from_unixtime(?)
                and u.login = ?"""
    numQuery(q, login, to)
  }

  def numIssueComments(login: String, to: Int): Future[Int] =  {
    val q = s"""select count(*)
                from users u, issue_comments ic
                where ic.user_id = u.id
                and ic.created_at < from_unixtime(?)
                and u.login = ?"""
    numQuery(q, login, to)
  }

  def numPullReqComments(login: String, to: Int): Future[Int] =  {
    val q = s"""select count(*)
                from users u, pull_request_comments prc
                where prc.user_id = u.id
                and prc.created_at < from_unixtime(?)
                and u.login = ?"""
    numQuery(q, login, to)
  }


  def numCodeReviews(login: String, to: Int): Future[Int] =  {
    val q = s"""select count(*)
                from users u, commit_comments ic
                where ic.user_id = u.id
                and ic.created_at < from_unixtime(?)
                and u.login = ?"""
    numQuery(q, login, to)
  }

  def numForked(login: String, to: Int): Future[Int] =  {
    val q = s"""select count(*)
                from projects p1, projects p2, users u
                where p1.forked_from = p2.id
                and p2.owner_id = u.id
                and p1.created_at < from_unixtime(?)
                and u.login = ?"""
    numQuery(q, login, to)
  }

  def numCommits(login: String, to: Int): Future[Int] = {
    val q = s"""select count(*)
                from commits c, users u
                where c.author_id = u.id
                and c.created_at < from_unixtime(?)
                and u.login = ?"""
    numQuery(q, login, to)
  }

  def inputStreamToByteArray(is: InputStream): String  =
    new String(Iterator continually is.read takeWhile (-1 !=) map (_.toByte) toArray)

  def req(url: String): Option[String] =
    catching(classOf[org.apache.http.conn.HttpHostConnectException]).opt {
      val client = HttpClients.createDefault()
      val httpGet = new HttpGet(url)

      client.execute(httpGet)
    }.map {
      response =>
        try {
          response.getStatusLine.getStatusCode match {
            case 200 =>
              printErr("HTTP: " + url + ": 200")
              Some(inputStreamToByteArray(response.getEntity.getContent))
            case _ =>
              printErr("HTTP: " + url + ": 404")
              None
          }
        } catch {
          case e: Exception => None
        } finally {
          response.close
        }
    }.getOrElse(None)


  def javaLibs(p: Project): Future[Seq[String]] = future {
    req(s"http://raw.github.com/${p.repo}/master/pom.xml").map {
      x =>
        catching(classOf[org.xml.sax.SAXParseException]).opt {
          scala.xml.XML.loadString(x)
        }.map {
          xml => (xml \\ "project" \\ "dependencies" \\ "dependency").map {
            dep => (dep \\ "artifactId").text.split("-")(0).split("_")(0)
          }
        }.getOrElse(List())
    }.getOrElse(List())
  }

  def rubyLibs(p: Project): Future[Seq[String]] = future {
    val reg1 = new Regex("""gem ?['"]([^'"]+)""")
    val gemfile = req(s"http://raw.github.com/${p.repo}/master/Gemfile").map {
      x => reg1.findAllIn(x).matchData.map{x => x.group(1)}
    }.getOrElse(List()).toSeq

    val reg2 = new Regex("""add_(.*_)?dependency[\s(]+["']([^"']+)""")
    val gemspec = req(s"http://raw.github.com/${p.repo}/master/${p.name}.gemspec").map {
      x => reg2.findAllIn(x).matchData.map{x => x.group(2)}
    }.getOrElse(List()).toSeq

    (gemfile ++ gemspec).distinct
  }

  def projectLibs(p: Project): Future[Seq[String]] = {
    if (projectLibs.contains(p.repo)) {
      projectLibs.getOrElse(p.repo, Future(List()))
    } else {
      val libs = p.lang match {
        case x : String if (x.equalsIgnoreCase("Java")) => javaLibs(p)
        case x : String if (x.equalsIgnoreCase("Ruby")) => rubyLibs(p)
        case _ => Future(List())
      }
      projectLibs.putIfAbsent(p.repo, libs).getOrElse(Future(List()))
    }
  }

  def getUser(login: String, to: Int) = async {
    val prj = await(projects(login, to))

    await(Future.traverse(prj){p => projectLibs(p)})

    val langs = prj.groupBy {
      p => p.lang
    }.map {
      langGroup => Language(langGroup._1,
        langGroup._2.flatMap{x => Await.result(projectLibs.getOrElse(x.repo, Future(List())), duration.Duration.Inf)}.distinct)
    }.filter{x => x.libraries.nonEmpty}.toSeq

    val perf = await(performance(login, to))

    ListMap(
      "login" -> login,
      "num_projects" -> prj.size,
      "num_languages" -> langs.size,
      "num_java_projects" -> prj.filter{x => x.lang == "Java"}.size,
      "num_ruby_projects" -> prj.filter{x => x.lang == "Ruby"}.size,
      "num_java_libs" -> prj.filter{x => x.lang == "Java"}.size,
      "num_ruby_libs" -> prj.filter{x => x.lang == "Ruby"}.size,
      "min_work_hour" -> perf.filter{x => x.commits > 0}.map{x => x.hour}.reduceOption(math.min).getOrElse(0),
      "max_work_hour" -> perf.filter{x => x.commits > 0}.map{x => x.hour}.reduceOption(math.min).getOrElse(0),
      "followers" -> await(numFollowers(login, to)),
      "watchers" -> await(numWatchers(login, to)),
      "pullreqs" -> await(numPullreqs(login, to)),
      "pullreq_comments" -> await(numPullReqComments(login, to)),
      "issues" -> await(numIssues(login, to)),
      "issue_comments" -> await(numIssueComments(login, to)),
      "num_commits" -> await(numCommits(login, to)),
      "code_reviews" -> await(numCodeReviews(login, to)),
      "forks" -> await(numCodeReviews(login, to))
    )
  }

  def getUserJSON(login: String, to: Int) = async {
    val prj = await(projects(login, to))
    val perf = await(performance(login, to))

    await(Future.traverse(prj){p => projectLibs(p)})

    val langs = prj.groupBy {
      p => p.lang
    }.map {
      langGroup => Language(langGroup._1,
        langGroup._2.flatMap{x => Await.result(projectLibs.getOrElse(x.repo, Future(List())), duration.Duration.Inf)}.distinct)
    }.filter{x => x.libraries.nonEmpty}.toSeq
    printErr("Done user " + login)

    User(login, prj, langs, perf)
  }

  def getUsers(src: List[String], to: Int): Future[List[ListMap[String, Any]]] =
    Future.traverse(src){login => getUser(login, to)}

  def getUsersJSON(src: List[String], to: Int): Future[List[User]] =
    Future.traverse(src){login => getUserJSON(login, to)}
}

case class Language(name: String, libraries: Seq[String])

case class Project(owner: String, name: String, lang: String) {
  def repo = s"$owner/$name"
}

case class WorkHour(hour: Int, commits: Int)

case class User(login: String, projects: Seq[Project], languages: Seq[Language],
                performance: Seq[WorkHour]) {

  def json = (
    "user" ->
      ("login" -> login) ~
        ("performance" ->
          performance.map {
            p =>
              (("hour" -> p.hour) ~ ("commits" -> p.commits))
          }) ~
        ("languages" ->
          languages.map {
            l =>
              (("name" -> l.name) ~ (("libs") -> l.libraries))
          }) ~
        ("projects" ->
          projects.map {
            p =>
              (("owner" -> p.owner) ~ (("name") -> p.name) ~ (("lang") -> p.lang))
          })
    )
}

object User {
  def empty = User("foo", List(), List(), List())
}