require 'httparty'

token = ""
instance = ""
course_id = ""

=begin

README

This script will mass delete all empty assignment groups. Below you will find the pre-instructions and instructions. If you've never run this before, or my mass_delete_assignments script, do both sets of instructions. If you have, jump to the instructions section.

**** Pre-Instructions ****

If this is your first time using this script, do the following only this time.

1. Install the httparty gem by opening terminal and typing, without quotes, 'gem install httparty'.

**** Instructions ****

1. Add your token, instance, and course ID above, on lines 3, 4, and 5, between the quotes. Save the file.
2. Now, we need to open terminal to that folder, so cd into that folder.
3. In terminal, type, without quotes, 'ruby mass_delete_empty_assignment_groups.rb', and watch it go!

=end

if instance.include? "https://"
else
  instance = "https://" + instance
end

response = HTTParty.get("#{instance}/api/v1/courses/#{course_id}/assignment_groups?per_page=3", headers: {"Authorization" => "Bearer #{token}"})
assignment_groups = response.body.scan(/\"id\":\d+,\"name\"/)
assignment_group_title = response.body.scan(/\"name\":\".+?\",\"position\"/)

link_headers = response.headers['link']
current_page = link_headers.match(/<.+?>; rel=\"current\"/).to_s.slice(1..-17)
last_page = link_headers.match(/rel=\"first\",<.+?>; rel=\"last\"/).to_s.slice(13..-14)
next_page = link_headers.match(/rel=\"current\",<.+?>; rel=\"next\"/).to_s.slice(15..-14)

puts "Generating a list of all assignments groups for the course."
puts

while current_page != last_page
  response = HTTParty.get("#{next_page}", headers: {"Authorization" => "Bearer #{token}"})
  (assignment_groups << response.body.scan(/\"id\":\d+,\"name\"/)).flatten!
  (assignment_group_title << response.body.scan(/\"name\":\".+?\",\"position\"/)).flatten!

  link_headers = response.headers['link']
  current_page = link_headers.match(/<.+?>; rel=\"current\"/).to_s.slice(1..-17)
  next_page = link_headers.match(/rel=\"current\",<.+?>; rel=\"next\"/).to_s.slice(15..-14)
  last_page = link_headers.match(/rel=\"first\",<.+?>; rel=\"last\"/).to_s.slice(13..-14)
end

counter, delete_counter = 0, 0

assignment_groups.each do |x|
  id = x.scan(/\d+/)
  results = HTTParty.get("#{instance}/api/v1/courses/#{course_id}/assignment_groups/#{id[0]}?include[]=assignments", headers: {"Authorization" => "Bearer #{token}"})
  if results.to_s.include?("\"assignments\":\[\]")
    HTTParty.delete("#{instance}/api/v1/courses/#{course_id}/assignment_groups/#{id[0]}", headers: {"Authorization" => "Bearer #{token}"})
    delete_counter += 1
    puts "Name >> #{assignment_group_title[counter].slice(8..-13)} \n****deleted****\nIts ID is #{id[0]}"
  else
    puts "Name >> #{assignment_group_title[counter].slice(8..-13)} \nskipped"
  end
  puts
  counter += 1
end

puts "\n#{delete_counter} assignment groups deleted\n\n"