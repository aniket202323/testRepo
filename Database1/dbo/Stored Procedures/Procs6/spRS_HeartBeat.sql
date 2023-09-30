CREATE PROCEDURE dbo.spRS_HeartBeat
@Name varchar(20)
 AS
    Select @Name 'Name', getDate() 'Date'
  return (0)
