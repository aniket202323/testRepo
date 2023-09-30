CREATE   PROCEDURE [dbo].[spRS_AdminAddTimeOption] 
@OptionId int = Null,
@OptionName varchar(100),
@Start_Date_SQL varchar(1000),
@End_Date_SQL varchar(1000)
AS
Declare @RRD_Id int
If @OptionId Is Null
 	 Begin
 	  	 Insert Into Report_Relative_Dates(Date_Type_Id, Default_Prompt_Desc, Start_Date_SQL, End_Date_SQL)
 	  	 Values(3, @OptionName, @Start_Date_SQL, @End_Date_SQL)
 	  	 Select @RRD_Id = Scope_Identity()
 	 End
Else
 	 Begin
 	  	 Update Report_Relative_Dates
 	  	  	 Set Default_Prompt_Desc = @OPtionName, 
 	  	  	  	 Start_Date_SQL = @Start_Date_SQL, 
 	  	  	  	 End_Date_SQL = @End_Date_SQL
 	  	  	 Where RRD_Id = @OptionId
 	  	 Select @RRD_Id = @OptionId
 	 End
Select * from Report_Relative_dates where RRD_ID = @RRD_Id
