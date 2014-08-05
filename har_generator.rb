require 'json'
require 'open-uri'

module PageTest
    class HarGenerator

        attr_reader :test_id, :test_url

        API_URLS = {
            'export'  => 'http://www.webpagetest.org/export.php?',
            'runtest' => 'http://www.webpagetest.org/runtest.php?'
        }

        DEFAULTS = {
            'runs'   => 5,
            'format' => 'json'
        }

        def initialize(options)
            fail unless options.include? 'k'
            fail unless options.include? 'url'

            @settings = DEFAULTS.merge( options )
            
            @test_url = URI.parse( @settings['url'] ).host

            @runtest_url = build_url( API_URLS['runtest'], @settings )
        end

        def get(poll = 10)
            test_data = run_test
            json_url  = test_data['jsonUrl']
            
            loop do
                json_parse_req( json_url ) do |resp|
                    status = resp['statusText']

                    yield( "Pending: #{status}" )

                    if status == 'Test Complete'
                        yield( "complete", open( @export_url ).read )
                        return nil
                    end
                end

                sleep( poll )
            end
        end

    private

        def run_test
            json_parse_req( @runtest_url ) do |resp|
                fail unless resp.include? 'data'

                test_data = resp['data']

                @test_id = test_data['testId']
                @export_url = build_url(API_URLS['export'], {
                    'test'   => @test_id,
                    'bodies' => 1,
                    'pretty' => 1
                })

                test_data
            end
        end

        def json_parse_req(url)
            yield( JSON.parse( open(url).read ) )
        end

        def build_url(domain, params)
            params.each_pair do |key, val|
                domain += "#{key}=#{val}&"
            end
            domain
        end

    end
end