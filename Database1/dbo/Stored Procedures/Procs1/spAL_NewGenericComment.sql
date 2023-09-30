CREATE PROCEDURE dbo.spAL_NewGenericComment
@SourceId BigInt,
@SourceType tinyint,
@TimeStamp Datetime,
@NewId int OUTPUT
AS
begin transaction
Insert Into Comments (Comment, User_Id, Modified_On, CS_Id) 
  values (' ',1, @TimeStamp, 1)
select @NewId = Scope_Identity()
if @SourceType = 1 --Test
  begin
    update tests set comment_id = @NewId where test_id = @SourceId
  end
else
  begin
    if @SourceType = 2  --Variable
      begin
        update Variables_Base set comment_id = @NewId where var_id = @SourceId
      end
    else
      begin
        if @sourceType = 3  --Product
          begin
            update products set comment_id = @NewId where prod_id = @SourceId
          end
        else
          begin
            if @SourceType = 4 --Event
               begin
                 update events set comment_id = @NewId where event_id = @SourceId
               end
            else               --Column
               begin
                 update sheet_columns set comment_id = @NewId where sheet_id = @SourceId and result_on = @TimeStamp
               end
          end
      end
  end
commit transaction
