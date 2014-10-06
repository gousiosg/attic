package ghprofiles

import scala.slick.session.Database
import Database.threadLocalSession
import scala.slick.jdbc.{StaticQuery => Q}
import java.util.concurrent.Executors
import scala.concurrent._
import scala.reflect.io.Path
import scala.io.Source
import java.io.File.{separator => /}

trait SODataExtraction {

  val executorService = Executors.newFixedThreadPool(Runtime.getRuntime.availableProcessors())
  implicit val executionContext = ExecutionContext.fromExecutorService(executorService)

  lazy val stopWords = {
    try {
      Source.fromFile(stopwords).getLines().foldLeft(
        new scala.collection.immutable.HashSet[String]()){
        (acc, x) => acc + x.trim
      }
    } catch { case e: Exception => Set[String]()}
  }

  def stopwords: String
  def db: Database
  lazy val conn = db

  def users = List[String]()
  def printErr(x: String) = System.err.println(x)

  def questions(from: Int, to: Int, incl: List[String]): List[(Int, String)] = {
    val q = """select p1.Id, u.EmailHash
               from posts p1, posts p2, users u
               where p2.Id = p1.AcceptedAnswerId
                 and p2.OwnerUserId = u.Id
                 and p1.CreationDate > from_unixtime(?)
                 and p1.CreationDate < from_unixtime(?)
            """
    val qs = conn withSession {
      Q.query[(Int, Int), (Int, String)](q).list(from, to)
    }.groupBy(l => l._2)

    val filtered = incl.map{x => qs.get(x)}.filter{x => x.isDefined}.map{x => x.get}.flatten
    printErr(s"${filtered.size} questions in period ${from} -> ${to}")
    filtered
  }

  def question(id: Int, dir: String): Future[Option[Int]] = future {
    val q = """select body, title, tags from posts where id = ?"""

    val result = conn withSession {
      Q.query[Int, (String, String, String)](q).list(id)
    }

    val title = strip(result(0)._2).split(' ').filter{x => x != ' ' || x != ""}.toList
    val tags = strip(result(0)._3.replace('>', ' ')).replace('<', ' ').split(' ').filter{x => x.trim != ""}.toList

    if (tags.contains("ruby") || tags.contains("java")) {
      val body = result(0)._1.toLowerCase.replaceAll("(\\r|\\n|\\t)", "").
        replaceAll("<pre.*>.*?</pre>", "").
        replaceAll("<a.*>.*?</a>", "").
        replaceAll("<blockquote.*>.*?</blockquote>", "").
        replaceAll("<img.*>.*?</img>", "").
        replaceAll("<p>","").replaceAll("</p>", "").
        replaceAll("<li>","").replaceAll("</li>", "").
        replaceAll("<ol>","").replaceAll("</ol>", "").
        replaceAll("<ul>","").replaceAll("</ul>", "").
        replaceAll("\\.", "").
        split(" ").
        filter{x => x.trim != ""}.
        map{x => strip(x).split(" ")}.flatten.
        filter{x => !stopWords.contains(strip(x))}.
        distinct.toList

      val question = (title ::: tags ::: body).map{x => x + "\n"}
      Path(s"${dir}${/}${id}").toFile.writeAll(question : _*)
      Some(id)
    } else {
      None
    }
  }

  def strip(s: String) =
    s.replaceAll("\\?", "").
      replaceAll("!", "").
      replaceAll("-", " ")
}
