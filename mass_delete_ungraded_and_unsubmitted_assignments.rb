require 'httparty'

token = ""
instance = ""
course_id = ""

=begin

README

This script will mass delete all assignments that don't have submissions or grades, which includes assignments, old quizzes (and it's various types, survey, etc), new quizzes, and graded discussions. Below you will find the pre-instructions and instructions. If you've never run this before, or my mass_delete_assignment_groups script, do both sets of instructions. If you have, jump to the instructions section.

**** Pre-Instructions ****

If this is your first time using this script, do the following only this time.

1. Install the httparty gem by opening terminal and typing, without quotes, 'gem install httparty'.

**** Instructions ****

1. Add your token, instance, and course ID above, on lines 3, 4, and 5, between the quotes. Save the file.
2. Now, we need to open terminal to that folder, so cd into that folder.
3. In terminal, type, without quotes, 'ruby mass_delete_ungraded_and_unsubmitted_assignments.rb', and watch it go!

=end

if instance.include? "https://"
else
  instance = "https://" + instance
end

response = HTTParty.get("#{instance}/api/v1/courses/#{course_id}/assignments?per_page=100", headers: {"Authorization" => "Bearer #{token}"})
assignments = response.body.scan(/\"id\":\d+,\"description\"/)
assignment_title = response.body.scan(/\"name\":\".+?\",\"submission_types\"/)
has_submissions = response.body.scan(/\"has_submitted_submissions\":\w+,/)

counter, delete_counter = 0, 0

link_headers = response.headers['link']
current_page = link_headers.match(/<.+?>; rel=\"current\"/).to_s.slice(1..-17)
last_page = link_headers.match(/rel=\"first\",<.+?>; rel=\"last\"/).to_s.slice(13..-14)
next_page = link_headers.match(/rel=\"current\",<.+?>; rel=\"next\"/).to_s.slice(15..-14)

puts "Generating a list of all assignments for the course."
## Check to see if commenting out this portion works, as I think it's redundant and actually adds the same thing more than once.
# if current_page != last_page
  while current_page != last_page
    response = HTTParty.get("#{next_page}", headers: {"Authorization" => "Bearer #{token}"})
    (assignments << response.body.scan(/\"id\":\d+,\"description\"/)).flatten!
    (assignment_title << response.body.scan(/\"name\":\".+?\",\"submission_types\"/)).flatten!
    (has_submissions << response.body.scan(/\"has_submitted_submissions\":\w+,/)).flatten!

    link_headers = response.headers['link']
    current_page = link_headers.match(/<.+?>; rel=\"current\"/).to_s.slice(1..-17)
    next_page = link_headers.match(/rel=\"current\",<.+?>; rel=\"next\"/).to_s.slice(15..-14)
    last_page = link_headers.match(/rel=\"first\",<.+?>; rel=\"last\"/).to_s.slice(13..-14)
  end
#   response = HTTParty.get("#{current_page}", headers: {"Authorization" => "Bearer #{token}"})
#   (assignments << response.body.scan(/\"id\":\d+,\"description\"/)).flatten!
#   (assignment_title << response.body.scan(/\"name\":\".+?\",\"submission_types\"/)).flatten!
#   (has_submissions << response.body.scan(/\"has_submitted_submissions\":\w+,/)).flatten!
# end

assignments.each do |x|
  a = x.scan(/\d+/)
  puts
  audit_getter = HTTParty.get("#{instance}/api/v1/audit/grade_change/assignments/#{a[0]}", headers: {"Authorization" => "Bearer #{token}"})

  while audit_getter.body.include?("internal_server_error")
    audit_getter = HTTParty.get("#{instance}/api/v1/audit/grade_change/assignments/#{a[0]}", headers: {"Authorization" => "Bearer #{token}"})
  end
  has_grades = audit_getter.body.scan(/\"events\":\[\],/)
  if has_submissions[counter].slice(28..-2) == "true"
    puts "#{assignment_title[counter].slice(8..-21)} \nhas submissions"
  elsif has_grades[0] != "\"events\":[],"
    puts "#{assignment_title[counter].slice(8..-21)} \nhas grades"
  else
    HTTParty.delete("#{instance}/api/v1/courses/#{course_id}/assignments/#{a[0]}", headers: {"Authorization" => "Bearer #{token}"})
    delete_counter += 1
    puts "#{assignment_title[counter].slice(8..-21)} \n****deleted****\nIts ID is #{a[0]}"
  end
  counter += 1
end
puts "\n\n#{delete_counter} assignments deleted\n\n"

=begin
.* Only delete assignments that have has_submitted_submissions = false
.* Only delete assignments that aren't graded
.* Looks at the link header 
.* and find the next page that way
.* navigate to the next page and obtain the next set of assignments 
.* currently crashes on last page results.
.* Ensure graded discussions follow same pattern
.* Ensure graded quizzes follow same pattern
.* Ensure new quizzes is the same as well
.* ungraded discussion            
.* practice quizzes
.* ungraded surveys
.* graded surveys
.* Make URL's relative and allow the user to give the instance and course, and then figure out the rest
.* Add documentation
* checkout finders other views and 
* Possibly save the deleted log to a file, so the user can look over which assignments were deleted, in case the end user wants a specific one restored.
=end
