# cxl.rb
#
# Copyright (c) 2011 Donald Cox <anthrotools@gmail.com>
#
# Documentation by Donald Cox
#
# Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
#
# == Overview
# A simple Ruby object wrapper for the cxl concept map file format defined by IHMC.
# The format is described here: http://cmap.ihmc.us/xml/CXL.html
#
# This format is currently only used by cmaptools, to my knowledge.
#
# The current implementation only reads the abstract concept information (concepts and propositions) from the CXL file.
# The current version also will likely not handle multi-links - eg multiple concepts link to or from a single linking
# phrase. Only one proposition is created per linking phase.
#
# === Future Enhancements
#  - more robust error handling, including a native suite of test data files
#  - more robust support for different map forms (e.g. multi-links)
#  - classes that capture the graphical presentation data in the CXL file
#  - make a gem
#  - ability to modify/update/delete/write to the file
#
# Eventually this may grow into a general concept map handling library, so it may include support for other formats
# such as that used by VUE (http://vue.tufts.edu/).
#
# == Example
#
#
# == Contact
#  - Donald Cox <anthrotools@gmail.com>
#

require 'nokogiri'


class Concept
  attr_reader :text, :id

  def initialize(cxl_concept_node)
    @id = cxl_concept_node.attribute('id').value
    @text = cxl_concept_node.attribute('label').value
  end

  def label
    @text
  end

  def name
    @text
  end

  def to_s
    @text
  end

  def ==(concept)
    return false unless concept
    @text == concept.text
  end

  def <=>(other_concept)
    @text <=> other_concept.text
  end

  def empty?
    @text.empty?
  end
  #need to define comparison implementations. where the action is at for this object
  #need to take into account different levels of comparison (Ruby, CXL, map/human)
  #in the simple case we'll say that nodes are the same if their text is the same, though in general CXL does not make this guarantee
end

class CXLConnection
  attr_reader :from, :to

  def initialize(connection_node)
    #should test to see if there's a performance difference converting the strings to ints
    @from = connection_node.attribute("from-id").value
    @to = connection_node.attribute("to-id").value
  end

  def start
    @from
  end

  def end
    @to
  end
end

class Proposition
  def initialize(lp_node, conn_list, concept_list)
    #add so error checking/catching in case the concept is not well formed
    #eg right now if source or dest are not found, you get method not found error
    @link_text = lp_node.attribute('label').value
    @lp_id = lp_node.attribute('id').value

    #should be find_alls below, and process the lists, But then this would need to be moved out of the
    #Proposition constructorw, hmmm
    begin
      src_id = (conn_list.find {|link| link.to == @lp_id}).from
    rescue
      src_id = nil
    end
    @src_concept = concept_list.find {|concept| concept.id == src_id}
    begin
    dest_id = (conn_list.find {|link| link.from == @lp_id}).to
    rescue
      dest_id == nil
    end
    @dest_concept = concept_list.find {|concept| concept.id == dest_id}
  end

  def linking_phrase
    @link_text
  end

  def source
    @src_concept
  end

  def destination
    @dest_concept
  end

  def is_self_ref?
    @src_concept == @dest_concept
  end

  def ==(prop)
    #let's assume well formed, though generally shouldn't
    @link_text == prop.linking_phrase &&
        @src_concept == prop.source &&
        @dest_concept == prop.destination
  end

  def <=>(prop)
    #not sure this is the best implementation, but not sure how component results should be combined in this case.
      self.to_s <=> prop.to_s
  end

  def well_formed?
    @src_concept && @dest_concept && !@src_concept.empty? && !@dest_concept.empty?
  end

  def to_s
    "#{@src_concept.to_s} #{@link_text} #{@dest_concept.to_s}"
  end

  def to_delimited(sep = ',')
     "#{@src_concept}#{sep}#{@link_text}#{sep}#{@dest_concept}"
  end

end

class ConceptMap
  attr_reader :file_path, :concepts, :propositions

  def initialize(cxl_file_path)
    @file_path = cxl_file_path
    @xml = Nokogiri::XML(File.open(cxl_file_path))
    @concepts = extract_concepts_from_xml
    @propositions = extract_props_from_xml
  end

  def has_concept?(concept)
    @concepts.find {|my_con| my_con == concept}
  end

  def has_proposition?(prop)
    @propositions.find {|my_prop| my_prop == prop}
  end

  def concepts_flattened
    @concepts.collect {|concept| concept.to_s}
  end

  def propositions_flattened
    @propositions.collect {|prop| prop.to_s}
  end

  private

  def extract_concepts_from_xml
    concept_list = []
    @xml.xpath("//*[local-name()='concept']").each do |concept|
        concept_list << Concept.new(concept)
    end
    concept_list
  end

  def extract_props_from_xml
    conn_list = []
    @xml.xpath("//*[local-name()='connection']").each do |node|
      conn_list << CXLConnection.new(node)
    end

    prop_list = []
    @xml.xpath("//*[local-name()='linking-phrase']").each do |node|
      prop_list << Proposition.new(node, conn_list, @concepts)
    end
    prop_list
  end

end
