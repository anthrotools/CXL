require '../lib/cxl_comparison'
require 'test/unit'

#$xml = Nokogiri::XML(File.open("cxltest.xml"))

class TestCXLComparison < Test::Unit::TestCase
  def test_compare
    comp = CXLComparison.new("PlantsSimple.cxl","PlantsSimple.cxl")
    assert_equal(false, comp.empty?)
    assert(comp.identical?)
    assert_equal(false, comp.disjoint?)
  end
end