# Demo data for local development and the public demo. Synthetic only: never seed real people or documents.
# Safe to run more than once: the demo account's requests are rebuilt each time.

demo = User.find_or_initialize_by(email_address: "demo@docdrop.test")
demo.update!(name: "Demo Requester", password: "docdrop-demo")
demo.document_requests.destroy_all

[
  { title: "Rental application", client_name: "Avery Example", client_email: "avery@example.com", due_on: 5.days.from_now,
    message: "Clear photos or scans are fine. PDF preferred.",
    items: { "Photo ID" => true, "Proof of income" => true, "Previous landlord reference" => false } },
  { title: "New client onboarding", client_name: "Blake Sample", client_email: "blake@example.com", due_on: 12.days.from_now,
    items: { "Signed engagement letter" => false, "Proof of address" => false } },
  { title: "Annual policy review", client_name: "Casey Placeholder", client_email: "casey@example.com",
    items: { "Current policy schedule" => true, "Claims history" => true } },
  { title: "Mortgage pre-approval", client_name: "Devon Fictional", client_email: "devon@example.com", due_on: 2.days.from_now,
    items: { "Last 3 payslips" => true, "Bank statements" => false, "Tax return" => false, "Photo ID" => true } }
].each do |attributes|
  items = attributes.delete(:items)
  request = demo.document_requests.create!(
    **attributes,
    checklist_items_attributes: items.keys.map { |name| { name: name } }
  )
  request.checklist_items.each { |item| item.update!(status: "received") if items[item.name] }
end

puts "Demo account ready: demo@docdrop.test / docdrop-demo (#{demo.document_requests.count} requests)"
