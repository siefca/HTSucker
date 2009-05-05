Gem::Specification.new do |s|
  s.name = %q{htsucker}
  s.version = "0.4.0"
  s.date = %q{2009-04-28}
  s.rubyforge_project = %q{htsucker}
  s.summary = %q{HTTP fetching class with limits and some heuristics}
  s.description = %q{HTSucker is a simple HTTP(S) reader with the ability to use timeouts, read/retry limits and transliterate body. It tries to guess content-type, charset and content-language by looking at HTML tags if any and uses domain-to-spoken-language-code mapping.}
  s.email = %q{pw@gnu.org}
  s.homepage = %q{http://randomseed.pl/htsucker}
  s.has_rdoc = true
  s.authors = ["Paweł Wilk"]
  s.add_dependency('htmlentities')
  s.add_dependency('bufferaffects')
  s.files = ["lib/htsucker.rb", "lib/htsucker/htsucker.rb", "lib/htsucker/domains_to_languages.rb", "lib/htsucker/errors.rb" ]
end
