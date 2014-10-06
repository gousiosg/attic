import sbt._
import Keys._

object GithubUserProfilesBuild extends Build {
  val Organization = "nl.tudelft.ghprofiles"
  val Name = "gh-profiles"
  val Version = "0.1.0-SNAPSHOT"
  val ScalaVersion = "2.10.2"

  lazy val project = Project (
    "github-user-profiles",
    file("."),
    settings = Defaults.defaultSettings ++ Seq(
      organization := Organization,
      name := Name,
      version := Version,
      scalaVersion := ScalaVersion,
      resolvers += Classpaths.typesafeReleases,
      libraryDependencies ++= Seq(
        "org.scala-lang" % "scala-reflect" % "2.10.2",
        "com.github.scopt" %% "scopt" % "3.1.0",
        "mysql" % "mysql-connector-java" % "5.1.24",
        "com.typesafe.slick" % "slick_2.10" % "1.0.0",
        "c3p0" % "c3p0" % "0.9.1.2",
        "org.json4s" %% "json4s-native" % "3.2.5",
        "org.scala-lang.modules" %% "scala-async" % "0.9.0-M2",
        "org.apache.httpcomponents" % "httpclient" % "4.3.1"
      )
    )
  )
}
