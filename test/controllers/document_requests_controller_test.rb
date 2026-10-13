require "test_helper"

class DocumentRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @request_record = document_requests(:rental)
  end

  def request_params(**overrides)
    { document_request: {
      title: "Loan documents", client_name: "Jo Client", client_email: "jo@example.com", due_on: 1.week.from_now.to_date,
      checklist_items_attributes: { "0" => { name: "Payslip" }, "1" => { name: "Bank statement" } }
    }.merge(overrides) }
  end

  test "requires sign in" do
    sign_out
    get new_document_request_path
    assert_redirected_to new_session_path
  end

  test "new" do
    get new_document_request_path
    assert_response :success
    assert_select "form input[name='document_request[checklist_items_attributes][0][name]']"
  end

  test "create with a checklist" do
    assert_difference [ "DocumentRequest.count" ], 1 do
      assert_difference "ChecklistItem.count", 2 do
        post document_requests_path, params: request_params
      end
    end

    request = DocumentRequest.order(:created_at).last
    assert_equal users(:one), request.user
    assert_redirected_to document_request_path(request)
  end

  test "create without checklist items shows an error" do
    assert_no_difference "DocumentRequest.count" do
      post document_requests_path, params: request_params(checklist_items_attributes: { "0" => { name: "" } })
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation li", "Add at least one document to the checklist"
  end

  test "show" do
    get document_request_path(@request_record)
    assert_response :success
    assert_select "h1", @request_record.title
    assert_select "#checklist li", 2
  end

  test "another requester's request is not found" do
    get document_request_path(document_requests(:others))
    assert_response :not_found

    patch document_request_path(document_requests(:others)), params: request_params
    assert_response :not_found

    assert_no_difference "DocumentRequest.count" do
      delete document_request_path(document_requests(:others))
    end
    assert_response :not_found
  end

  test "update renames, adds and removes checklist items" do
    address = checklist_items(:rental_address)

    patch document_request_path(@request_record), params: { document_request: {
      title: "Rental application (updated)",
      checklist_items_attributes: {
        "0" => { id: checklist_items(:rental_id).id, name: "Photo ID" },
        "1" => { id: address.id, name: "Proof of address", _destroy: "1" },
        "2" => { name: "Reference letter" }
      }
    } }

    assert_redirected_to document_request_path(@request_record)
    @request_record.reload
    assert_equal "Rental application (updated)", @request_record.title
    assert_equal [ "Photo ID", "Reference letter" ], @request_record.checklist_items.map(&:name)
    assert_not ChecklistItem.exists?(address.id)
  end

  test "update can't remove the last checklist item" do
    visa = document_requests(:visa)
    patch document_request_path(visa), params: { document_request: {
      checklist_items_attributes: { "0" => { id: checklist_items(:visa_passport).id, _destroy: "1" } }
    } }

    assert_response :unprocessable_entity
    assert ChecklistItem.exists?(checklist_items(:visa_passport).id)
  end

  test "destroy" do
    assert_difference "DocumentRequest.count", -1 do
      delete document_request_path(@request_record)
    end
    assert_redirected_to root_path
  end
end
