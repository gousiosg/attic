require "test/unit"

require 'committee-favouritism/citation_parser'

class CitationParserTest < Test::Unit::TestCase

  include CommitteeFavouritism

  def test_extract_names

    citations = Hash.new
    citations["Andrea Capiluppi , Patricia Lago , Maurizio Morisio, Characteristics of Open Source Projects, Proceedings of the Seventh European Conference on Software Maintenance and Reengineering, p.317, March 26-28, 2003"] = 3
    citations["Robert L. Glass , Iris Vessey , Sue A. Conger, Software tasks: intellectual or clerical?, Information and Management, v.23 n.4, p.183-191, Oct. 1992 "] = 3
    citations["Stephen H. Kan , Brian Thomas, Metrics and Models in Software Quality Engineering, Addison-Wesley Longman Publishing Co., Inc., Boston, MA, 1994"] = 2
    citations["Alpern, B., Cocchi, A., Fink, S., and Grove, D. Efficient implementation of Java interfaces: Invokeinterface considered harmless. In OOPSLA '01: Proceedings of the 16th ACM SIGPLAN conference on Object oriented programming, systems, languages, and applications (2001), ACM Press, pp. 108-124."] = 4
    citations["Kazi, I. H., Chen, H. H., Stanley, B., and Lilja, D. J. Techniques for obtaining high performance in Java programs. ACM Comput. Surv. 32, 3 (2000), 213-240."] = 4
    citations["Blelloch, G. E., and Cheng, P. On bounding time and space for multiprocessor garbage collection. In PLDI '99: Proceedings of the ACM SIGPLAN 1999 conference on Programming language design and implementation (1999), ACM Press, pp. 104-117."] = 2

    citations.keys.each do |k|
      extracted = extract_names(k)
      assert(extracted.size == citations[k],
             "#{extracted.size} != #{citations[k]}: \n #{extracted}")
    end
  end

end