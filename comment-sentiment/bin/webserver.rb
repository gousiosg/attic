require 'webrick'
require 'erb'
require 'mongo'

class Ratable
  attr_accessor :owner, :repo, :issue_id, :comments
  def initialize(hash)
    hash.each { |k, v| instance_variable_set("@#{k}", v) }
  end

end

class TmplData
  attr_accessor :ratable

  def initialize(arg)
    @ratable = arg
  end

  def get_binding
    binding
  end
end

class Index < WEBrick::HTTPServlet::AbstractServlet
  def tmpl
    @tmpl ||= File.open('index.erb').read
    @tmpl
  end

  def data
    @data ||= Proc.new {
      File.open('comments.txt').lines.map do |x|
        owner, repo, issue_id, comments = x.split(/,/)
        next if comments.nil?
        comments.split(/#-#/)
        Ratable.new({:owner => owner, :repo => repo,
                     :issue_id => issue_id, :comments => comments})
      end
    }.call
    @data
  end

  def do_GET(request, response)
    status, content_type, body = index(request)

    response.status = status
    response['Content-Type'] = content_type
    response.body = body
  end

  def index(request)
    html = ERB.new(tmpl)
    comments = TmplData.new(data.sample)
    return 200, 'text/html', html.result(comments.get_binding)
  end
end

class Answer < WEBrick::HTTPServlet::AbstractServlet

  def do_POST(request, response)
    status, content_type, body = save_answers(request)

    response.status = status
    response['Content-Type'] = content_type
    response.body = body
  end

  # Save POST request into a text file
  def save_answers(request)
    # Check if the user provided a name
    if (filename = request.query['first_name'] )
      f = File.open("save-#{filename}.#{Time.now.strftime('%H%M%S')}.txt", 'w')

      # Iterate over every POST'ed value and persist it to file
      request.query.collect { | key, value | f.write("#{key}: #{value}\n") }
      f.close
    end

    # Return OK (200), content-type: text/plain, and a plain-text "Saved! Thank you." notice
    return 200, "text/plain", "Saved! Thank you."
  end
end


# Initialize our WEBrick server
if $0 == __FILE__ then
  server = WEBrick::HTTPServer.new(:Port => 8000)
  server.mount '/', Index
  server.mount '/rate', Answer
  trap 'INT' do server.shutdown end
  server.start
end


# vim: set sta sts=2 shiftwidth=2 sw=2 et ai :
