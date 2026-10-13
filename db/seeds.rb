# Demo data for local development and the public demo. Synthetic only: never seed real people or documents.
# Safe to run more than once.

demo = User.find_or_initialize_by(email_address: "demo@docdrop.test")
demo.update!(name: "Demo Requester", password: "docdrop-demo")

puts "Demo account ready: demo@docdrop.test / docdrop-demo"
