# cxl_test.rb
#
# Copyright (c) 2011 Donald Cox <anthrotools@gmail.com>
#
# Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
#
# == Prerequisites
# - Obtain PlantsSimple.cxl from http://cmap.ihmc.us/xml/PlantsSimple.cxl and put it in the test directory
#
# == Contact
#  - Donald Cox <anthrotools@gmail.com>
#

require '../lib/cxl'
require 'test/unit'


class TestConcept < Test::Unit::TestCase
  def setup
    @concept_plant = Nokogiri::XML::fragment('<concept id="1" label="Plants"/>').children.first
    @concept_leaf = Nokogiri::XML::fragment('<concept id="2" label="Leaves"/>').children.first
  end

  def test_extraction
    concept = Concept.new(@concept_plant)
    assert_equal("Plants", concept.label)
    assert_equal("1", concept.id)
  end

  def test_equals
    left = Concept.new(@concept_plant)
    right = Concept.new(@concept_plant)

    assert(left == right)
  end

  def test_notequals
    left = Concept.new(@concept_plant)
    right = Concept.new(@concept_leaf)

    assert_equal(false, (left == right))
  end
end

class TestCXLConnection < Test::Unit::TestCase
  def test_extraction
    link = Nokogiri::XML::fragment('<connection from-id="1" to-id="3"/>').children.first
    test_conn = CXLConnection.new(link)
    assert_equal("1",test_conn.from)
    assert_equal("3", test_conn.to)
  end
end

class TestProposition < Test::Unit::TestCase
  def setup
    @concept_plant = Concept.new(Nokogiri::XML::fragment('<concept id="1" label="Plants"/>').children.first)
    @concept_leaf = Concept.new(Nokogiri::XML::fragment('<concept id="2" label="Leaves"/>').children.first)
    @concept_root = Concept.new(Nokogiri::XML::fragment('<concept id="5" label="Roots"/>').children.first)
    @have_node = Nokogiri::XML::fragment('<linking-phrase id="3" label="have"/>').children.first
    @grow_node = Nokogiri::XML::fragment('<linking-phrase id="4" label="grow"/>').children.first
    @link13 = CXLConnection.new(Nokogiri::XML::fragment('<connection from-id="1" to-id="3"/>').children.first)
    @link32 = CXLConnection.new(Nokogiri::XML::fragment('<connection from-id="3" to-id="2"/>').children.first)
    @link14 = CXLConnection.new(Nokogiri::XML::fragment('<connection from-id="1" to-id="4"/>').children.first)
    @link42 = CXLConnection.new(Nokogiri::XML::fragment('<connection from-id="4" to-id="2"/>').children.first)
    @link45 = CXLConnection.new(Nokogiri::XML::fragment('<connection from-id="4" to-id="5"/>').children.first)
    @link31 = CXLConnection.new(Nokogiri::XML::fragment('<connection from-id="3" to-id="1"/>').children.first)
  end

  def test_extract
    prop = Proposition.new(@have_node,
                          [@link13,@link32],
                          [@concept_plant, @concept_leaf])
    assert_equal("Plants have Leaves", prop.to_s)
  end

  def test_equal
    prop1 = Proposition.new(@have_node,
                          [@link13,@link32],
                          [@concept_plant, @concept_leaf])
    prop2 = Proposition.new(@have_node,
                          [@link13,@link32],
                          [@concept_plant, @concept_leaf])
    assert(prop1 == prop2)
  end

  def test_notequal_phrase
    proph = Proposition.new(@have_node,
                          [@link13,@link32,@link14,@link42],
                          [@concept_plant, @concept_leaf])
    propg = Proposition.new(@grow_node,
                          [@link13,@link32,@link14,@link42],
                          [@concept_plant, @concept_leaf])
    assert(!(proph == propg))
  end

  def test_notequal_prop
     proph = Proposition.new(@have_node,
                          [@link13,@link32,@link14,@link45],
                          [@concept_plant, @concept_leaf,@concept_root])
    propg = Proposition.new(@grow_node,
                          [@link13,@link32,@link14,@link45],
                          [@concept_plant, @concept_leaf, @concept_root])
    assert(!(proph == propg))
  end

  def test_not_selfref
    prop = Proposition.new(@have_node,
                          [@link13,@link32],
                          [@concept_plant, @concept_leaf])
    assert(!prop.is_self_ref?)
  end

  def test_selfref
    prop = Proposition.new(@have_node,
                          [@link13,@link31],
                          [@concept_plant, @concept_leaf])
    assert(prop.is_self_ref?)
  end

  def test_delimiteddefault
    prop = Proposition.new(@have_node,
                          [@link13,@link32],
                          [@concept_plant, @concept_leaf])
    assert_equal("Plants,have,Leaves", prop.to_delimited)
  end

  def test_delimitedset
    prop = Proposition.new(@have_node,
                          [@link13,@link32],
                          [@concept_plant, @concept_leaf])
    assert_equal("Plants:have:Leaves", prop.to_delimited(':'))
  end

  def test_wellformed
    prop = Proposition.new(@have_node,
                          [@link13,@link32],
                          [@concept_plant, @concept_leaf])
    assert(prop.well_formed?)
  end

  def test_malformed
    prop = Proposition.new(@have_node,
                          [@link13],
                          [@concept_plant, @concept_leaf])
    assert(!prop.well_formed?)
  end
end

class TestConceptMap < Test::Unit::TestCase
  def test_extract
    map = ConceptMap.new("../test/PlantsSimple.cxl")
    assert_equal(2, map.concepts.size)
    assert_equal(["Plants","Leaves"], map.concepts_flattened)
    assert_equal(1, map.propositions.size)
    assert_equal("Plants have Leaves", map.propositions_flattened.first)
  end
end
