CREATE Procedure dbo.spGE_GetPath
 	  	  	 @PU_Id int,
 	  	  	 @Path_Id int Output
AS
Select @Path_Id = Path_Id 
From PrdExec_Path_Unit_Starts 
Where PU_Id = @PU_Id
And End_Time is NULL
