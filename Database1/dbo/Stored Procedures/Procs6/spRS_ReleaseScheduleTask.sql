CREATE PROCEDURE dbo.spRS_ReleaseScheduleTask
@Schedule_Id int = Null,
@Computer_Name varchar(20) = Null,
@Process_Id  smallInt = Null
AS
If @Schedule_Id Is Null
  Begin
    Update Report_Schedule
      Set 
        Computer_Name = Null,
        Process_Id = Null,
        Status = 0
      Where
        Computer_Name = @Computer_Name and
        Process_Id = @Process_Id
    End
Else
  Begin
    Declare @Sid int
    Select @Sid = Schedule_Id
    From Report_Schedule
    Where Schedule_Id = @Schedule_Id
    If @Sid Is Null
      Return (2) -- no such schedule id
    Else
      Begin
        Update Report_Schedule
          Set Computer_Name = Null, 
            Process_Id = Null, 
            Status = 0
            Where Schedule_Id = @Schedule_Id
          Return (1)
      End
End
