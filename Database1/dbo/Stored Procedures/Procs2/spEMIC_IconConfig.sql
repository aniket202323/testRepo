Create Procedure dbo.spEMIC_IconConfig 
@ListType int, @Id1 int, @Desc nvarchar(50) 
AS
if @ListType = 2
  begin
    if @Id1 = 0
      begin
        insert into Icons (Icon_Desc) values(@Desc)
        select icon_id = Scope_Identity()
      end
    else
      begin
        update Icons set Icon_Desc = @Desc where Icon_Id = @Id1
        select icon_id = @Id1
      end
  end
else if @ListType = 3
  delete from icons where icon_id = @id1
else if @ListType = 4
  update icons set icon = null where icon_id = @id1
