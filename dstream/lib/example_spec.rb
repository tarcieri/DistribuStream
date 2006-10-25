require File.dirname(__FILE__) + '/example'

context 'A new Example object' do
    setup do
        @example = Example.new
    end

    specify 'should return Example' do
        @example.example.should.equal 'Example'
    end
end
