CREATE PROCEDURE dbo.spRS_IEAddWebPageParameter
@RWP_Name varchar(50),
@RP_Name varchar(50)
 AS
Declare @RWP_Id int
Declare @RP_Id int
Declare @Exists int
Select @RWP_Id = RWP_Id From Report_Webpages Where Upper(LTrim(RTrim(File_Name))) = Upper(LTrim(RTrim(@RWP_Name)))
Select @RP_Id = RP_Id From Report_Parameters Where Upper(LTrim(RTrim(RP_Name))) = Upper(LTrim(RTrim(@RP_Name)))
--Select @Rwp_id, @rp_id
If (@RWP_Id Is Not Null) AND (@RP_Id Is Not Null) 
 	 Begin
 	  	 Select @Exists = Rpt_WebPage_Param_Id from Report_Webpage_Parameters where RWP_ID = @RWP_Id and rp_id = @RP_Id
 	  	 If (@Exists Is Null) 
 	  	  	 Begin
 	  	  	  	 Insert Into Report_Webpage_Parameters(RP_Id, RWP_Id) Values(@RP_Id, @RWP_Id)
 	  	  	 End
 	 End 
