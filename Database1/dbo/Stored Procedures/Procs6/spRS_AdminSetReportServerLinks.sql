CREATE PROCEDURE dbo.spRS_AdminSetReportServerLinks
@Link_Id Int = Null,
@Link_Type_Id int, 
@Link_Name varchar(50),
@URL varchar(7000)
AS
Declare @New_Link_Id int
-----------------
-- Add New Link
-----------------
If @Link_Id Is Null
  Begin
    Insert Into Report_Server_Links(Link_Type_Id, Link_Name, URL)
    Values(@Link_Type_Id, @Link_Name, @URL)
    Select @New_Link_Id = Scope_Identity()
  End
------------------------
-- Update Existing Link
------------------------
Else
  Begin
    Update Report_Server_Links Set
 	   Link_Type_Id = @Link_Type_Id,
      Link_Name = @Link_Name,
      URL = @URL
    Where Link_Id = @Link_Id
    Select @New_Link_Id = @Link_Id  
  End
Exec spRS_AdminGetReportServerLinks @New_Link_Id
