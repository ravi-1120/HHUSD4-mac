/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_SelectedUserWrapper.cls
* @description - Wraps the User object to enable a user selection UI
* @createdate - Feb 4th, 2014
*
*/

public class MRK_SelectedUserWrapper {
	public User u {get; set;}
	public Boolean selected {get; set;}

	public MRK_SelectedUserWrapper(User usr) {
		u = usr;
		selected = false;
	}
}