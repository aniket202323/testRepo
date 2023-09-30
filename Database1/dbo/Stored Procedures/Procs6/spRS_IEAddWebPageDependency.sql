CREATE PROCEDURE dbo.spRS_IEAddWebPageDependency
@RWP_Name varchar(50),
@Value varchar(255), 
@RDT_Id int
 AS
Declare @RWP_Id int
Declare @Exists int
-- Get Web Page Id From The File Name
Select @RWP_Id = RWP_Id From Report_Webpages Where Upper(LTrim(RTrim(File_Name))) = Upper(LTrim(RTrim(@RWP_Name)))
If @RWP_Id Is Null
  Return (0)
-- Check If This Dependency Already Exists
Select @Exists = RWD_Id From Report_Webpage_Dependencies Where
 	 RDT_Id = @RDT_Id AND
 	 RWP_ID = @RWP_Id AND
 	 Upper(LTrim(RTrim(Value))) = Upper(LTrim(RTrim(@Value)))
-- If It Doesnt Exist Then Insert
If (@Exists Is Null) 
 	 Begin
 	  	 Insert Into Report_Webpage_Dependencies(RWP_Id, RDT_Id, Value)
 	  	 Values(@RWP_Id, @RDT_Id, @Value)
 	 End
