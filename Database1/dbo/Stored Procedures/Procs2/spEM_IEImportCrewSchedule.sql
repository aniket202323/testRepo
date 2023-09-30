CREATE PROCEDURE dbo.spEM_IEImportCrewSchedule
 	 @PL_Desc 	  	 nvarchar(50),
 	 @PU_Desc 	  	 nvarchar(50),
 	 @Crew_Desc 	  	 nVarChar(10),
 	 @Shift_Desc 	  	 nVarChar(10),
 	 @sStart_Time 	 nVarChar(100),
 	 @sEnd_Time 	  	 nVarChar(100),
 	 @Comment  	  	 nvarchar(255),
 	 @User_Id 	  	 int,
 	 @TransType 	  	 nVarChar(1)
AS
Declare 	 @PL_Id  	  	  	  	 int,
 	  	 @PU_Id 	  	  	  	 int,
 	  	 @Comment_Id 	  	  	 int,
 	  	 @ExistingComment 	 nvarchar(255),
 	  	 @Start_Time  	  	 datetime,
 	  	 @End_Time  	  	  	 datetime,
 	  	 @CS_Id 	  	  	  	 int
Select @PL_Id = Null
Select @PU_Id = Null
Select @CS_Id = Null
Select @Comment_Id = Null
------------------------------------------------------------------------------------------
-- Trim Parameters
------------------------------------------------------------------------------------------
Select @PL_Desc = LTrim(RTrim(@PL_Desc))
Select @PU_Desc = LTrim(RTrim(@PU_Desc))
Select @Crew_Desc = LTrim(RTrim(@Crew_Desc))
Select @Shift_Desc = LTrim(RTrim(@Shift_Desc))
Select @sStart_Time = LTrim(RTrim(@sStart_Time))
Select @sEnd_Time = LTrim(RTrim(@sEnd_Time))
Select @Comment = LTrim(RTrim(@Comment))
-- Verify Arguments 
If @PL_Desc = '' or @PL_Desc IS NULL
 BEGIN
   Select 'Failed - Production Line Missing'
   Return(-100)
 END
If  @PU_Desc = '' or @PU_Desc IS NULL 
 BEGIN
   Select 'Failed - Production Unit Missing'
   Return(-100)
 END
If  @Crew_Desc = '' or @Crew_Desc IS NULL
 BEGIN
   Select 'Failed - Crew Info Missing'
   Return(-100)
 END
If  @Shift_Desc = '' or @Shift_Desc IS NULL
 BEGIN
   Select 'Failed - Shift Info Missing'
   Return(-100)
 END
If @sStart_Time = ''  or @sStart_Time IS NULL
 BEGIN
   Select 'Failed - Start Time Missing'
   Return(-100)
 END
If @sEnd_Time = ''  or @sEnd_Time IS NULL
 BEGIN
   Select 'Failed - End Time Missing'
   Return(-100)
 END
If Len(@sStart_Time) <> 14
 BEGIN
   Select 'Failed - Start Time not valid'
   Return(-100)
 END
If Len(@sEnd_Time)  <> 14
 BEGIN
   Select 'Failed - End Time not valid'
   Return(-100)
 END
SELECT @Start_Time = 0
SELECT @Start_Time = DateAdd(year,convert(int,substring(@sStart_Time,1,4)) - 1900,@Start_Time)
SELECT @Start_Time = DateAdd(month,convert(int,substring(@sStart_Time,5,2)) - 1,@Start_Time)
SELECT @Start_Time = DateAdd(day,convert(int,substring(@sStart_Time,7,2)) - 1,@Start_Time)
SELECT @Start_Time = DateAdd(hour,convert(int,substring(@sStart_Time,9,2)) ,@Start_Time)
SELECT @Start_Time = DateAdd(minute,convert(int,substring(@sStart_Time,11,2)),@Start_Time)
SELECT @End_Time = 0
SELECT @End_Time = DateAdd(year,convert(int,substring(@sEnd_Time,1,4)) - 1900,@End_Time)
SELECT @End_Time = DateAdd(month,convert(int,substring(@sEnd_Time,5,2)) - 1,@End_Time)
SELECT @End_Time = DateAdd(day,convert(int,substring(@sEnd_Time,7,2)) - 1,@End_Time)
SELECT @End_Time = DateAdd(hour,convert(int,substring(@sEnd_Time,9,2)) ,@End_Time)
SELECT @End_Time = DateAdd(minute,convert(int,substring(@sEnd_Time,11,2)),@End_Time)
Select @PL_Id = PL_Id 
  From Prod_Lines
  Where PL_Desc = @PL_Desc
If @PL_Id Is Null
  Begin
 	 Select 'Failed - Production Line not Found'
 	 Return(-100)
  End
Select @PU_Id = PU_Id 
  From Prod_Units 
  Where PU_Desc = @PU_Desc And PL_Id = @PL_Id
If @PU_Id IS NULL
  Begin
 	 Select 'Failed - Production Unit not Found'
 	 Return(-100)
  End
------------------------------------------------------------------------------------------
--Insert or Update Crew Schedule   	  	  	  	 
------------------------------------------------------------------------------------------
Select @CS_Id = CS_Id 
  from Crew_Schedule 
  where PU_Id = @PU_Id and Start_Time = @Start_Time
If @TransType = 'D' 
 Begin
 	 If @CS_Id is null
 	   Begin
 	  	 Select 'Failed - StartTime for delete not found'
 	  	 Return(-100)
 	   End
 	 Execute spEMCSC_PutCrewSched  1,@User_Id,@PU_Id,@Start_Time,@End_Time,@Crew_Desc,@Shift_Desc,@Comment_Id,@CS_Id
 	 Return(0)
 End
If @Comment <> '' and @Comment IS NOT NULL 
  Begin
    Insert into Comments (Comment, User_Id, Modified_On, CS_Id) Values(@Comment,@User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3)
    Select @Comment_Id = Scope_Identity()
    If @Comment_Id IS NULL
        Select 'Warning - Unable to create comment'
  END
/* Fix Any Start and End Times*/ 
DELETE FROM Crew_Schedule WHERE Start_Time >= @Start_Time and  End_Time <= @End_Time  and PU_Id = @PU_Id 
UPDATE Crew_Schedule SET End_Time =  @Start_Time,User_Id = @User_Id  WHERE Start_Time  < @Start_Time AND  End_Time > @Start_Time  and PU_Id = @PU_Id 
UPDATE Crew_Schedule SET Start_Time =  @End_Time,User_Id = @User_Id  WHERE Start_Time  < @End_Time AND  End_Time > @End_Time and PU_Id = @PU_Id 
INSERT INTO Crew_Schedule (PU_Id, Start_Time, End_Time, Crew_Desc, Shift_Desc, Comment_Id,User_Id)
          Values (@PU_Id, @Start_Time, @End_Time, @Crew_Desc, @Shift_Desc, @Comment_Id,@User_Id)
Return(0)
