def load(path)
  eval(File.read(path), binding, path) # rubocop:disable Security/Eval
end

load File.expand_path("./src/main.rb")

module MiTest
  class MiTestCase < ::MTest::Unit::TestCase
    def test_parse_input_valid
      input = {
        main: "ok",
        confidence: 0.9,
        fit_score: 0.95
      }.to_json
      result, error = Mi.parse_input(input)
      assert_equal("ok", result)
      assert_nil(error)
    end

    def test_parse_input_confidence_too_low
      input = {
        main: "almost ok",
        confidence: 0.5,
        fit_score: 0.95
      }.to_json
      result, error = Mi.parse_input(input)
      assert_nil(result)
      assert_equal("confidence is less than 0.8", error)
    end

    def test_parse_input_fit_score_too_low
      input = {
        main: "partial",
        confidence: 0.9,
        fit_score: 0.5
      }.to_json
      result, error = Mi.parse_input(input)
      assert_nil(result)
      assert_equal("fit_score is less than 0.8", error)
    end

    def test_parse_input_json_error
      result, error = Mi.parse_input("this is not json")
      assert_equal("this is not json", result)
      assert_nil(error)
    end

    def test_extract_text
      json = {
        "candidates" => [
          {
            "content" => {
              "parts" => [
                { "text" => "Hello!" }
              ]
            }
          }
        ]
      }.to_json
      assert_equal("Hello!", Mi.extract_text(json))
    end

    def test_build_second_response_schema_structure
      schema = Mi.build_second_response_schema(first_response_schema: { "type": "STRING" })
      assert_equal("OBJECT", schema[:type])
      assert_equal(["main", "confidence", "fit_score"], schema[:propertyOrdering])
      assert_equal({ "type": "STRING" }, schema[:properties][:main])
      assert_equal({ "type": "NUMBER" }, schema[:properties][:confidence])
      assert_equal({ "type": "NUMBER" }, schema[:properties][:fit_score])
    end

    def test_mi_schema_json_output
      json_str = Mi.mi_schema(text: "hello", response_schema: { "type": "STRING" })
      data = JSON.parse(json_str)
      assert_equal("hello", data["contents"][0]["parts"][0]["text"])
      assert_equal("application/json", data["generationConfig"]["responseMimeType"])
      assert_equal("STRING", data["generationConfig"]["responseSchema"]["type"])
    end
  end
end

MTest::Unit.new.run
