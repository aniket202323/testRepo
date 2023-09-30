Create Procedure dbo.spEMPE_IsEncrypted 
@PID int,
@User_Id int
AS
select IsEncrypted from Parameters
where Parm_Id = @PID
