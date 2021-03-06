# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /things?filter', type: :request do
  before(:all) do
    @thing_1 = FactoryBot.create(:thing, only: FactoryBot.create(:only))
    @thing_2 = FactoryBot.create(:thing, only: FactoryBot.create(:only))
    @active_set = ActiveSet.new(Thing.all)
  end

  context '.json' do
    let(:results) { JSON.parse(response.body) }
    let(:result_ids) { results.map { |f| f['id'] } }

    before(:each) do
      get things_path(format: :json),
          params: { filter: instructions }
    end

    ApplicationRecord::FIELD_TYPES.each do |type|
      [1, 2].each do |id|
        let(:matching_item) { instance_variable_get("@thing_#{id}") }

        paths = all_possible_paths_for(type)
        paths.shuffle.take(paths.size / 2).each do |path|
          context "{ #{path}: }" do
            let(:instructions) do
              {
                path => filter_value_for(object: matching_item, path: path)
              }
            end

            it { expect(result_ids).to eq [matching_item.id] }
          end
        end
      end
    end

    ApplicationRecord::FIELD_TYPES.combination(2).each do |type_1, type_2|
      [1, 2].each do |id|
        context "matching @thing_#{id}" do
          let(:matching_item) { instance_variable_get("@thing_#{id}") }

          paths = all_possible_path_combinations_for(type_1, type_2)
          paths.shuffle.take(paths.size / 2).each do |path_1, path_2|
            context "{ #{path_1}:, #{path_2} }" do
              let(:instructions) do
                {
                  path_1 => filter_value_for(object: matching_item, path: path_1),
                  path_2 => filter_value_for(object: matching_item, path: path_2)
                }
              end

              it { expect(result_ids).to eq [matching_item.id] }
            end
          end
        end
      end
    end
  end
end
