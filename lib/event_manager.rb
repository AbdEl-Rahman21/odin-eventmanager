# frozen_string_literal: true

require 'google/apis/civicinfo_v2'
require 'csv'
require 'erb'

WEEKDAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
CONTENTS =
  CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') { |file| file.puts form_letter }
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/, '')

  if phone_number.length == 11 && phone_number[0] == '1'
    phone_number.slice!(1, 10)
  elsif phone_number.length != 10
    'Invalid phone number!'
  else
    phone_number
  end
end

def get_best_hours
  CONTENTS.rewind

  hours = []

  CONTENTS.each do |row|
    hours.push(DateTime.strptime(row[:regdate], '%m/%d/%Y %k').hour)
  end

  hours = hours.each_with_object(Hash.new(0)) { |v, k| k[v] += 1 }

  hours.each_pair { |k, v| puts k if v == hours.max_by(&:last)[1] }
end

def get_best_day
  CONTENTS.rewind

  days = []

  CONTENTS.each do |row|
    days.push(DateTime.strptime(row[:regdate], '%m/%d/%Y').wday)
  end

  puts WEEKDAYS[
         days.each_with_object(Hash.new(0)) { |v, k| k[v] += 1 }.max_by(&:last)[
           0
         ]
       ]
end

def create_letter
  CONTENTS.rewind

  erb_template = ERB.new File.read('form_letter.erb')

  CONTENTS.each do |row|
    id = row[0]

    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    phone_number = clean_phone_number(row[:homephone])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
  end
end

puts "Event Manager Initialized!\n\n"

# create_letter
get_best_hours
get_best_day
