CREATE PROCEDURE dbo.spRS_AddReportWebPage
@File_Name varchar(50),
@Title varchar(50),
@Prompt1 varchar(50) = Null,
@Prompt2 varchar(50) = Null,
@Prompt3 varchar(50) = Null,
@Prompt4 varchar(50) = Null,
@Prompt5 varchar(50) = Null,
@Exists int output
 AS
/*
If @Exists Is Null
  Begin
    Select @Exists = RWP_Id
    From Report_WebPages
    Where Title = @Title
  End
*/
If @Exists Is Null -- Add a new page
  Begin
    Insert Into Report_WebPages(File_Name, Title, Prompt1, Prompt2, Prompt3, Prompt4, Prompt5)
    Values(@File_Name, @Title, @Prompt1, @Prompt2, @Prompt3, @Prompt4, @Prompt5)
    Select @Exists = Scope_Identity()
    If @@Error = 0
      Return (0)  -- New Row was successfully added
    Else
      Return (1)  -- Error adding new row
  End
Else -- Update an existing page
  Begin
    Update Report_WebPages
    Set File_Name = @File_Name,
 	 Title = @Title,
 	 Prompt1 = @Prompt1, 
 	 Prompt2 = @Prompt2,
 	 Prompt3 = @Prompt3, 
 	 Prompt4 = @Prompt4,
 	 Prompt5 = @Prompt5
    Where RWP_Id = @Exists
    If @@Error = 0
      Return (2)  -- Existing Row was successfully updated
    Else
      Return (3)  -- Error updating existing row
  End
