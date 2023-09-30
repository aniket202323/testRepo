CREATE PROCEDURE dbo.spEM_DropEventConfig
  @EC_Id int,
  @UserId int
AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
BEGIN TRANSACTION
   DELETE FROM Event_Configuration_Data WHERE EC_Id = @EC_Id
   IF @@ERROR > 0 
    BEGIN
     ROLLBACK
     RETURN(0)
    END
   DELETE FROM Event_Configuration WHERE EC_Id = @EC_Id
   IF @@ERROR > 0 
    BEGIN
     ROLLBACK
     RETURN(0)
    END
COMMIT
RETURN(0)
