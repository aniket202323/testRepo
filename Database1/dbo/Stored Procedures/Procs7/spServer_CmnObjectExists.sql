CREATE PROCEDURE dbo.spServer_CmnObjectExists
@ObjectName nVarChar(250),
@Type int,
@Exists int OUTPUT
AS
-- Types
-- 1 Table
-- 2 Stored Procedure
Declare
  @ObjectId int
Select @ObjectId = NULL
If (@Type = 1)
  Select @ObjectId = Id From sysobjects Where (Name = @ObjectName) And (Type = 'U')
Else
  If (@Type = 2)
    Select @ObjectId = Id From sysobjects Where (Name = @ObjectName) And (Type = 'P')
If (@ObjectId Is NULL)
  Select @Exists = 0
Else
  Select @Exists = 1
