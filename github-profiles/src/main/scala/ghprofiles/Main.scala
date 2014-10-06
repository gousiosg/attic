package ghprofiles

import org.json4s.JsonDSL.WithDouble._
import org.json4s.native.JsonMethods
import scala.slick.session.Database
import scala.io.Source._
import scala.concurrent.{Future, duration, Await}
import scala.reflect.io.Path
import scala.collection.immutable.ListMap
import scala.Some
import java.io.File.{separator => /}

case class Config(connString: String, driver: String, user: String,
                  password: String, file: Option[String] = None,
                  mode: String = "gh", stopwords: String = "")

object ConfigGH {
  val connString = "jdbc:mysql://localhost/ghtorrent"
  val driver = "com.mysql.jdbc.Driver"
  val user   = "ghtorrent"

  def apply(c: Config) =
    c.copy(connString = connString, driver = driver, user = user)
}

object ConfigSO {
  val connString = "jdbc:mysql://localhost/stackoverflow"
  val driver = "com.mysql.jdbc.Driver"
  val user   = "stackoverflow"

  def apply(c: Config) =
    c.copy(connString = connString, driver = driver, user = user)
}

object Main extends App {

  val parser = new scopt.OptionParser[Config]("scopt") {
    head("Github Profiles", "1.0")

    opt[String]('c', "connString") valueName ("<connection string>") action {
      (x, c) =>
        c.copy(connString = x)
    } text ("JDBC connection string")

    opt[String]('d', "driver") valueName ("<driver>") action {
      (x, c) =>
        c.copy(driver = x)
    } text ("Driver to use for connecting to the DB")


    opt[String]('u', "user") valueName ("<user>") action {
      (x, c) =>
        c.copy(user = x)
    } text ("User for connecting to the DB")

    opt[String]('p', "passwd") valueName ("<password>") action {
      (x, c) =>
        c.copy(password = x)
    } text ("User for connecting to the DB")

    opt[String]('f', "file") valueName ("<inputfile>") action {
      (x, c) =>
        c.copy(file = Some(x))
    } text ("Common users from input file (MD5 hashed, one per line)")

    opt[String]('m', "mode") valueName ("<gh or so>") action {
      (x, c) =>
        c.copy(mode = x)
    } text ("Mode of extraction: Github or StackOverflow")

    opt[String]('w', "stopwords") valueName ("<gh or so>") action {
      (x, c) =>
        c.copy(stopwords = x)
    } text ("Stopwords file for SO data extraction")
  }

  var conf = parser.parse(args, Config("","","","")) map { config => config} getOrElse { exit(1) }

  conf match {
    case x if(x.mode.equalsIgnoreCase("gh")) => (new GithubMode(ConfigGH(conf))).run
    case x if(x.mode.equalsIgnoreCase("so")) => (new StackOverflowMode(ConfigSO(conf))).run
    case _ => s"No such mode: ${conf.mode}"
  }
}

trait Mode {
  import com.mchange.v2.c3p0.ComboPooledDataSource

  val periods = List(1325376000, 1338508800, 1356998400, 1370044800)

  def conf: Config
  def run
  def users: List[String]

  def getDB = {
    val ds = new ComboPooledDataSource
    ds.setDriverClass(conf.driver)
    ds.setUser(conf.user)
    ds.setPassword(conf.password)
    ds.setJdbcUrl(conf.connString)
    ds.setInitialPoolSize(2)
    ds.setMaxPoolSize(32)
    Database.forDataSource(ds)
  }

  def usrs: List[String] = conf.file match {
    case None    => users.toList
    case Some(x) => fromFile(x, "UTF8").getLines.toList

    //      println(soUsers.size + " stack oveflow users")
    //      val ghUsers = usersWithEmailsHashed()
    //      val ghEmails = ghUsers.map{x => x._2}.toSet
    //      println(ghEmails.size + " github users")
    //      val common = soUsers.intersect(ghEmails)

    //val md5Idxsd = ghUsers.foldLeft(Map[String, (String, String, String, String)]()){(acc, x) => acc ++ Map(x._2 -> x)}
    //common.foreach(x => println(md5Idxsd.get(x).mkString(",")))
    //println(common.size + " common users")
    //      val ghUsersIdx = ghUsers.foldLeft(Map[String, String]()){(acc, x) => acc ++ Map(x._2 -> x._1)}
    //      common.map{x => ghUsersIdx.getOrElse(x, "")}.filter(x => !x.isEmpty).toList
  }
}

class GithubMode(config: Config) extends Mode with GHDataExtraction with JsonMethods {

  Runtime.getRuntime.addShutdownHook(new Thread(){
    override def run() = {
      println("Saving retrieved data")
      val toDump = projectLibs.foldLeft(Map[String, List[String]]()){
        (acc, x) => acc ++ Map(x._1 -> Await.result(x._2, duration.Duration.Inf).toList)}

      Path(projectLibsFile).toFile.writeAll(pretty(render(toDump)))
    }
  })

  def conf = this.config
  def db = getDB
  def users = users()

  def run = {
    printErr("Github profile extraction")
    def toCSV(input: ListMap[String, Any]) : String = (input.values.mkString(",") + "\n")
    //input.foldLeft(new StringBuffer()){(acc, x) => acc.append(x._2).append(','); acc}.toString

    def csvHeader(input: ListMap[String, Any]) : String = (input.keys.mkString(",") + "\n")

    //  List(1325376000, 1338508800, 1356998400, 1370044800).foreach { x =>
    //    val d = new java.util.Date(x * 1000L)
    //    val fname = s"profiles-${d.getDay + 1}-${d.getMonth + 1}-${1900 + d.getYear}"
    //    printErr(s"Doing ${fname}")
    //
    //    val results = Await.result(getUsers(usrs, x), duration.Duration.Inf)
    //
    //    Path(fname).toFile.writeAll(
    //      (csvHeader(results.head) :: results.map{x => toCSV(x)}).toList: _*)
    //  }

    val results = Await.result(Future.traverse(periods) {to => getUsersJSON(usrs.map{x => x.split(',')(0)}, to)}, duration.Duration.Inf)
    periods.zip(results).foreach { x =>
      (new java.io.File(s"${x._1}${/}github${/}")).mkdirs()
      x._2.foreach { y =>
        val profile =
          y.languages.map{x => x.name + "\n"}.toList :::
            y.projects.map{x => x.name + "\n"}.toList :::
            y.languages.flatMap{x => x.libraries}.map{x => x + "\n"}.toList

        Path(s"${x._1}${/}github${/}${y.login}").toFile.writeAll(profile : _*)
      }
    }
  }
}

class StackOverflowMode(config: Config) extends Mode with SODataExtraction {
  def conf = config
  def db = getDB
  def stopwords = config.stopwords

  def run = {
    printErr("StackOverflow data extraction")
    var usrHash = usrs
    usrHash = usrHash.map{x => val y = x.split(','); if(y.size > 1)y(1) else {printErr(x); "foo"};}

    periods.zip(periods.tail).map {
      case (from, to) =>
        val dir = s"${from}${/}stackoverflow"
        (new java.io.File(dir)).mkdirs()
        Await.result(Future.traverse(questions(from, to, usrHash)) {
          case (qid, hash) => question(qid, dir)
        }, duration.Duration.Inf)
    }
  }
}