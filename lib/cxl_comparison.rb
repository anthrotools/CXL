require '../lib/cxl'


class CXLComparison
  #assume that the files have already been validated
  def initialize(reference_map_file_path, evaluated_map_file_path)
    @ref_map = ConceptMap.new(reference_map_file_path)
    @eval_map = ConceptMap.new(evaluated_map_file_path)
    @comparison_results = {}
  end

  def simple_strict_compare
    #check the math to see that I agree with this
    @comparison_results[:ref_only_concepts] = @ref_map.concepts_flattened - @eval_map.concepts_flattened
    @comparison_results[:shared_concepts] = @ref_map.concepts_flattened - @comparison_results[:ref_only_concepts]
    @comparison_results[:eval_only_concepts] = @eval_map.concepts_flattened - @ref_map.concepts_flattened

    @comparison_results[:ref_only_props] = @ref_map.propositions_flattened - @eval_map.propositions_flattened
    @comparison_results[:shared_props] = @ref_map.propositions_flattened - @comparison_results[:ref_only_props]
    @comparison_results[:eval_only_props] = @eval_map.propositions_flattened - @ref_map.propositions_flattened
    self
  end

  def compare
    self.simple_strict_compare if @comparison_results.empty?
  end

  def empty?
    self.compare if @comparison_results.empty?
    @comparison_results[:ref_only_concepts].empty? &&
        @comparison_results[:ref_only_props].empty? &&
        @comparison_results[:eval_only_concepts].empty? &&
        @comparison_results[:eval_only_props].empty? &&
        @comparison_results[:shared_concepts].empty? &&
        @comparison_results[:shared_props].empty?
  end

  def identical?
    self.compare if @comparison_results.empty?
    #technically I believe two empty maps are identical,
    #so I don't have to ensure that there are shared concepts and
    #propositions empty above will do that
    @comparison_results[:ref_only_concepts].empty? &&
        @comparison_results[:ref_only_props].empty? &&
        @comparison_results[:eval_only_concepts].empty? &&
        @comparison_results[:eval_only_props].empty?
  end

  def disjoint?
    self.compare if @comparison_results.empty?
    #can't have shared propositions without shared concepts, so only need to check concepts
    @comparison_results[:shared_concepts].empty? &&
        ((!@comparison_results[:ref_only_concepts].empty?) ||
         (!@comparison_results[:eval_only_concepts].empty?))
  end

  def output_as_text(file_object)
    file_object.puts "Simple Concept Map Comparison"
    file_object.puts "Reference map: #{@ref_map.file_path}"
    file_object.puts "Evaluated map: #{@eval_map.file_path}"
    file_object.puts ""
    file_object.puts "Concepts only in the Reference Map"
    @comparison_results[:ref_only_concepts].each {|elt| file_object.puts elt}
    file_object.puts ""
    file_object.puts "Propositions only in the Reference Map"
    @comparison_results[:ref_only_props].each {|elt| file_object.puts elt}
    file_object.puts ""
    file_object.puts "Concepts shared by both Maps"
    @comparison_results[:shared_concepts].each {|elt| file_object.puts elt}
    file_object.puts ""
    file_object.puts "Propositions shared by both Maps"
    @comparison_results[:shared_props].each {|elt| file_object.puts elt}
    file_object.puts ""
    file_object.puts "Concepts only in the Evaluated Map"
    @comparison_results[:eval_only_concepts].each {|elt| file_object.puts elt}
    file_object.puts ""
    file_object.puts "Propositions only in the Evaluated Map"
    @comparison_results[:eval_only_props].each {|elt| file_object.puts elt}

  end

end