require 'spec_helper'
require 'rails_helper'

describe 'Agents', js: true do
  it 'should be able to see all agents' do
    visit('/')
    click_link 'Names'
    within all('.col-sm-12')[0] do
      expect(page).to have_content("Showing Names: 1 - 3 of 3")
    end
  end

  it 'displays agent page' do
    visit('/')
    click_link 'Names'
    click_link 'Linked Agent 1' # prefer this agent because it's a "full" record
    expect(current_path).to match(/agents\/people\/\d+/)
    expect(page).to have_content('Linked Agent 1')
  end
end
