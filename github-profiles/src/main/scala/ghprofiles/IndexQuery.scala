package ghprofiles

import java.io.File
import scala.io.Source
import scala.collection.immutable.HashSet

object IndexQuery extends App {

  def getLines(path: String) = {
    val source = Source.fromFile(path)
    val lines = source.getLines.toArray
    source.close()
    lines
  }

  val path = "1338508800"
  val github = (new File(s"${path}/github")).list.sortWith((a,b) => a.compareTo(b) > 0)

  val terms = github.toIterable.foldLeft(new HashSet[String]()){
    (acc, file) =>
      val toRead = s"${path}/github/${file}"
      acc ++ getLines(toRead)
  }.toList.sortWith((a,b) => a.compareTo(b) > 0)

  println("Zipping")
  println("Constructing term index")
  val termIdx = terms.zipWithIndex.foldLeft(Map[String, Int]()){(acc, x) => acc ++ Map(x._1 -> x._2)}
  println("Constructing dev index")
  val devIdx = github.zipWithIndex.foldLeft(Map[Int, String]()){(acc, x) => acc ++ Map(x._2 -> x._1)}

  println("Initializing DTM array")
  val dtm = Array.ofDim[Short](github.size, terms.length)

  println("Indexing documents")
  for(i <- 0 to (github.length - 1)) {
    val toIdx = path + "/github/" + github(i)
    getLines(toIdx).foreach {
      x =>
        if (termIdx.contains(x))
          dtm(i)(termIdx(x)) = 1.toShort
        else
          dtm(i)(termIdx(x)) = 0.toShort
    }
  }

  println(s"Indexing done: ${dtm.length} documents, ${dtm(0).length} terms")

  val so = (new File(s"${path}/stackoverflow")).list.sortWith((a,b) => a.compareTo(b) > 0)
  so.par.foreach {
    question =>
      val query = getLines(s"${path}/stackoverflow/${question}").map{x => x.trim}.distinct
      val queryTerms = query.map{x => termIdx.get(x)}.filter{x => x.isDefined}.map{x => x.get}.sorted
      val queryVector = Array.fill[Short](terms.length)(0.toShort)
      queryTerms.foreach{x => queryVector(x) = 1.toShort}

      val results = dtm.zipWithIndex.map {
        case (document, i) =>
          val x = devIdx(i)
          val sim = cosineSimilarity(queryVector, document)
          (x, sim)
      }.sortWith((a,b) => a._2 > b._2).map{x => x._1}.take(10)

      println(s"${question},${results.mkString(",")}")
  }

  def cosineSimilarity(x: Array[Short], y: Array[Short]): Double = {
    require(x.size == y.size)
    dotProduct(x, y)/(magnitude(x) * magnitude(y))
  }

  def dotProduct(x: Array[Short], y: Array[Short]): Long = {
    //(for((a, b) <- x zip y) yield a * b) sum
    require(x.size == y.size)
    var z = 0L
    for(i <- 0 to (x.size - 1)) {
      z += (x(i) * y(i))
    }
    z
  }

  def magnitude(x: Array[Short]): Double = {
    var z = 0
    for(i <- 0 to (x.size - 1)) {
      z += (x(i) * x(i))
    }
    math.sqrt(z)
  }
}
