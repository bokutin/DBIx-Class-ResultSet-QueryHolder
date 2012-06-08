require 'rubygems'

require 'active_record'
require 'benchmark'

ActiveRecord::Base.establish_connection(
  :adapter  => 'postgresql',
  :host     => 'localhost',
  :username => 'foo',
  :password => '',
  :database => ''
)

class Artist < ActiveRecord::Base
  self.table_name = 'artist'
  has_many :albums
end

class Album < ActiveRecord::Base
  self.table_name = 'album'
  has_many :covers
end

class Cover < ActiveRecord::Base
  self.table_name = 'cover'
end

def slurp
  artist = Artist.find_by_name("artist1")
  artist.name
  artist.albums.all(:order => "name").each do |album|
    cover = album.covers.all(:conditions => { :name => "cover1" }).first
    cover.id
  end
end

slurp

n = 200
Benchmark.bm do |x|
  x.report { n.times do; slurp; end }
end

#foil bokutin % ruby benchmark/script/activerecord.rb
#       user     system      total        real
#   4.430000   0.170000   4.600000 (  6.200819)
# 200/6.200819=32.25380389267933800357

# vim: set sw=2 :
