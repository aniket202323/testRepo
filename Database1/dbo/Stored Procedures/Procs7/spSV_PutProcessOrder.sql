Create Procedure dbo.spSV_PutProcessOrder
@Transaction_Type int,
@Path_Id int,
@Process_Order_Id int,
@Process_Order nvarchar(100),
@User_General_1 nvarchar(255),
@User_General_2 nvarchar(255),
@User_General_3 nvarchar(255),
@Extended_Info nvarchar(255),
@User_Id int
AS
If @Path_Id = 0
  Select @Path_Id = NULL
DECLARE @Entry_On datetime,
@Check int
Select @Check = count(PP_Id) From Production_Plan Where (Path_Id = @Path_Id OR (Path_Id is NULL and @Path_Id is NULL)) and Process_Order = @Process_Order and PP_Id <> @Process_Order_Id
If @Check > 0 Return(-100)
If @Transaction_Type = 2
  Begin
    Declare @User_General_1_Updated bit, @User_General_2_Updated bit, @User_General_3_Updated bit, @Extended_Info_Updated bit
    Declare @Compare_User_General_1 nvarchar(255), @Compare_User_General_2 nvarchar(255), @Compare_User_General_3 nvarchar(255), @Compare_Extended_Info nvarchar(255)
    Select @Compare_User_General_1 = User_General_1,
   	  @Compare_User_General_2 = User_General_2,
   	  @Compare_User_General_3 = User_General_3,
 	  	  @Compare_Extended_Info = Extended_Info
    From Production_Plan
    Where PP_Id = @Process_Order_Id
    Select @User_General_1_Updated = 0, @User_General_2_Updated = 0, @User_General_3_Updated = 0, @Extended_Info_Updated = 0
    If (@Compare_User_General_1<>@User_General_1 or (@Compare_User_General_1 is NULL and @User_General_1 is NOT NULL) or (@Compare_User_General_1 is NOT NULL and @User_General_1 is NULL))
      Select @User_General_1_Updated = 1
    If (@Compare_User_General_2<>@User_General_2 or (@Compare_User_General_2 is NULL and @User_General_2 is NOT NULL) or (@Compare_User_General_2 is NOT NULL and @User_General_2 is NULL))
      Select @User_General_2_Updated = 1
    If (@Compare_User_General_3<>@User_General_3 or (@Compare_User_General_3 is NULL and @User_General_3 is NOT NULL) or (@Compare_User_General_3 is NOT NULL and @User_General_3 is NULL))
      Select @User_General_3_Updated = 1
    If (@Compare_Extended_Info<>@Extended_Info or (@Compare_Extended_Info is NULL and @Extended_Info is NOT NULL) or (@Compare_Extended_Info is NOT NULL and @Extended_Info is NULL))
      Select @Extended_Info_Updated = 1
    If (Select Convert(int, @User_General_1_Updated) + Convert(int, @User_General_2_Updated) + 
               Convert(int, @User_General_3_Updated) + Convert(int, @Extended_Info_Updated)) > 0
      Begin
 	  	     Select @Entry_On = dbo.fnServer_CmnGetDate(getUTCdate())
 	  	     
 	  	     Update Production_Plan Set 
 	  	       Extended_Info = @Extended_Info,
 	  	       User_General_1 = @User_General_1,
 	  	       User_General_2 = @User_General_2,
 	  	       User_General_3 = @User_General_3,
 	  	       User_Id = @User_Id,
 	  	       Entry_On = @Entry_On
 	  	     Where PP_Id = @Process_Order_Id
 	  	  	 End
  End
Return (1)
