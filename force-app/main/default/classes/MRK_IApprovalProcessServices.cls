/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_IApprovalProcessServices.cls
* @description - interface for approval process services
* @createdate - Mar 24th, 2014
*
*/

public interface  MRK_IApprovalProcessServices {

	/**
	 * allowSubmitForApproval
	 *
	 * looks at the state of the record to determine if it can be submitted
	 * for approval
	 */
	Boolean allowSubmitForApproval(Id objectId, Id requestorUserId);

	/**
	 * allowRecallApprovalRequest
	 *
	 * looks at the state of the record to determine if the approval request can
	 * be recalled
	 */
	Boolean allowRecallApprovalRequest(Id objectId, Id requestorUserId);

	/**
	 * allowApproveReject
	 *
	 * looks at the state of the record to determine if an approve or reject
	 * can be made
	 */
	Boolean allowApproveReject(Id objectId, Id requestorUserId);

	/**
	 * getAvailableApprovers
	 *
	 * returns a list of users who are able to approve the given object
	 * (objectId) for the given submitter (submitterUserid)
	 */
	List<User> getAvailableApprovers(Id submitterUserid, Id objectId);

	/**
	 * getDefaultApprover
	 *
	 * returns the user who should be the default approver
	 * for the given submitter (submitterUserid) and given object (objectId)
	 */
	User getDefaultApprover(Id submitterUserid, Id objectId);

	/**
	 * getDefaultApprover
	 *
	 * provides approver visibility to object (objectId) submitted for approval
	 * if approver does not have visibility to it
	 */
	Boolean ensureApproverVisibiltyToObject(Id approverUserid, Id objectId);


	/**
	 * getPostSubmitForApprovalRedirectURL
	 *
	 * returns the URL the submitter (submitterUserId) should be redirected to
	 * after the approval request has been submitted
	 */
	String getPostSubmitForApprovalRedirectURL(Id objectId, Id submitterUserId);


}