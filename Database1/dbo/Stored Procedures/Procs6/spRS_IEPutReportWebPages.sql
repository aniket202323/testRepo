CREATE PROCEDURE dbo.spRS_IEPutReportWebPages
 	   @RWP_Id 	  	 int 	  	  	 --NOT USED
 	 , @File_Name 	  	 varchar(50) 	  	 --This is our "functional Key"
 	 , @Title 	  	 varchar(50)  = NULL
 	 , @Comment_Id 	  	 Int 	      = NULL
 	 , @Prompt1 	  	 Varchar(50)  = NULL
 	 , @Prompt2 	  	 Varchar(50)  = NULL
 	 , @Prompt3 	  	 Varchar(50)  = NULL
 	 , @Prompt4 	  	 Varchar(50)  = NULL
 	 , @Prompt5 	  	 Varchar(50)  = NULL
 	 , @Version 	  	 Varchar(20)  = NULL
 	 , @Detail_Desc 	  	 Varchar(255) = NULL
 	 , @RWP_Id_Target 	 Int OUTPUT
AS
/*  For use with IMPORT of report packages
    MSI-MT 8-15-2000
    MSI/MT/1-9-2001 rewrite to include constraint check
    local variables use prefix 'l' or no underscore
*/
Declare @lStatus 	  	 Int
Declare @lUniqueFileName 	 Bit
Declare @lUniqueTitle 	  	 Bit
Select @lStatus = -9191
Select @RWP_Id_Target = -9191
If @RWP_Id = 0 OR @RWP_Id Is NULL
    BEGIN
 	 Select @lStatus = -2000
 	 GOTO END_OF_PROC
    END
/* Check for Existence of unique dbo.Report_WebPages.File_Name */
If EXISTS(SELECT RWP.RWP_Id  FROM Report_WebPages RWP  WHERE RWP.File_Name = @File_Name)
SELECT @lUniqueFileName = 1 Else SELECT @lUniqueFileName = 0
/* Check for Existence of unique dbo.Report_WebPages.Title */
If EXISTS(SELECT RWP.RWP_Id  FROM Report_WebPages RWP  WHERE RWP.Title = @Title )
SELECT @lUniqueTitle = 1 Else SELECT @lUniqueTitle = 0
If @lUniqueFileName = 0 	  	  	  	  	 --No UniqueName, might insert
    BEGIN
 	 If @lUniqueTitle = 0 	  	  	  	 --No title violation, OK to insert
 	     BEGIN
 	  	 INSERT INTO Report_WebPages 
 	  	       (File_Name,  Title,  Comment_Id,  Prompt1,  Prompt2,  Prompt3,  Prompt4,  Prompt5,  Version,  Detail_Desc)
 	  	 VALUES(@File_Name, @Title, @Comment_Id, @Prompt1, @Prompt2, @Prompt3, @Prompt4, @Prompt5, @Version, @Detail_Desc)
 	 
 	  	 If @@Error <> 0 Select @lStatus = @@Error Else Select @lStatus = 20
 	  	 Select @RWP_Id_Target = Scope_Identity()
 	  	 If @@Error <> 0 Select @lStatus = @@Error
 	     END
 	 Else If @lUniqueTitle = 1 	  	  	 --Yes title violation; can't insert
 	     BEGIN
 	  	 SELECT @RWP_Id_Target = @RWP_Id
 	  	 SELECT @lStatus = 21 	  	  	 --insert held back, constraint violation
 	     END
    END
Else If @lUniqueFileName = 1 	  	  	  	 --Yes UniqueName exists; might update
    BEGIN
 	 SELECT @RWP_Id_Target = RWP.RWP_Id  FROM Report_WebPages RWP  WHERE RWP.File_Name = @File_Name
 	 If @lUniqueTitle = 0 	  	  	  	 --No title violation; do update
 	     BEGIN
 	  	 UPDATE Report_WebPages
 	  	 SET    Title=@Title, Comment_Id=@Comment_Id 
 	  	      , Prompt1=@Prompt1, Prompt2=@Prompt2, Prompt3=@Prompt3, Prompt4=@Prompt4, Prompt5=@Prompt5
 	  	      , Version=@Version, Detail_Desc=@Detail_Desc
 	  	 WHERE  File_Name = @File_Name
 	  	 If @@Error <> 0 Select @lStatus = @@Error Else Select @lStatus = 10
 	     END
 	 Else If @lUniqueTitle = 1 	  	  	 --Yes title violation
 	     BEGIN
 	  	 SELECT @lStatus = 13 	  	  	 --update held back, constraint violation
 	     END
    END
END_OF_PROC:
Return (@lStatus)
