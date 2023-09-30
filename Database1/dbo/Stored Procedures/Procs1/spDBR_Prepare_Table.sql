CREATE Procedure dbo.spDBR_Prepare_Table
@paramxml text = '<Root></Root>'
AS
  if (not @paramxml like '<Root></Root>')
  begin
 	  	 create table #Headers
 	  	 (
 	  	   header varchar(50),
 	  	   col int
 	  	 )
    create table #columndata
    (
      cdrow int,
      value varchar(50)
    )
    create table #DataTable
    (
      row int
    )
    declare @hDoc int
    declare @@altercmd nvarchar(4000)
    declare @@insertcmd nvarchar(4000)
    declare @singlerow varchar(7000)
    declare @singlecol varchar(7000)
    declare @index int, @previousindex int, @readlen int, @rowlength int
    declare @c_index int, @pc_index int, @c_readlen int
    declare @@finalselect nvarchar(4000)
    select @@finalselect = 'select '
    if (@paramxml like '%<Root>%')
    begin
      Exec sp_xml_preparedocument @hDoc OUTPUT, @paramxml
 	  	 insert into #Headers 
 	  	 select header, col from OpenXml(@hdoc, '/Root/_x0023_paramvalue[@Row="1"]', 1) with ([header] varchar(50) '@Header', [col] int '@Col')
 	  	 update #Headers 
 	  	 set Header = case when isnumeric(Header) = 1 then (dbo.fnDBTranslate(N'0', Header, Header))
 	  	  	  	  	  	 else (Header) end
 	  	 declare @@header varchar(50), @@col int, @@columncount int
 	  	 select @@columncount = 0
 	  	 Declare Query_Cursor INSENSITIVE CURSOR
 	  	  	 For Select * from #Headers
 	  	  	 For Read Only
 	  	  	 Open Query_Cursor  
 	  	  Query_Loop:
 	  	  	 Fetch Next From Query_Cursor Into @@header, @@col
 	  	  	 If (@@Fetch_Status = 0)
 	  	  	 Begin
 	  	  	  	 select @@altercmd = 'alter table #datatable add [' + @@header + '] varchar(50)'
 	  	  	  	 execute sp_executesql @@altercmd
 	  	  	  	 select @@columncount = @@columncount + 1
 	  	  	  	 if (@@columncount > 1)
 	  	  	  	 begin
 	  	  	  	  	 select @@finalselect = @@finalselect + ','
 	  	  	  	 end
 	  	  	  	 select @@finalselect = @@finalselect + '[' + @@header + ']'
 	  	  	  	 Goto Query_Loop
 	  	  	 End
 	  	 Close Query_Cursor 
 	  	 deallocate Query_Cursor
                insert into #datatable (row) Select Row From     OpenXml( @hdoc, '/Root/_x0023_paramvalue[@Col="1"]', 1) with ([Row] int '@Row')
 	  	 declare @@currentcolumn int, @@xpath varchar(1000), @@updatequery nvarchar(4000), @@currentcolumnname nvarchar(50)
 	  	 select @@currentcolumn = 1
 	  	 while @@currentcolumn <= @@columncount
 	  	 begin
 	  	  	 select @@xpath = '/Root/_x0023_paramvalue[@Col="' + convert(varchar(10), @@currentcolumn) + '"]'
 	  	  	 delete from #columndata
 	  	  	 insert into #columndata (cdrow, value) 
 	  	  	 Select     Row, Value From     OpenXml(@hdoc, @@xpath , 1) with ([Row] int '@Row', [Value] varchar(50) '@Value')
 	  	  	 select @@currentcolumnname = header from #headers where col = @@currentcolumn
 	  	  	 select @@updatequery = 'update #datatable set [' + @@currentcolumnname + ']=value from #columndata where row = cdrow'
 	  	  	 execute sp_executesql @@updatequery
 	  	  	 select @@currentcolumn = @@currentcolumn + 1
 	  	 end
      Exec sp_xml_removedocument @hDoc
    end
    else
    begin
      select @previousindex = 0
      select @index = CharIndex(';', @paramxml, @previousindex)
      select @readlen = @index - @previousindex
      if (@readlen > 0)
      begin
        select @singlerow = substring(@paramxml, @previousindex, @readlen)
        select @previousindex = @index + 1
        select @rowlength = len(@singlerow)
        select @pc_index = 0
 	 select @c_index = CharIndex(',', @singlerow, @pc_index)
        select @c_readlen = @c_index - @pc_index
 	 select @@columncount = 0
 	 while @c_readlen > 0
        begin
         select @singlecol = substring(@singlerow, @pc_index, @c_readlen)
         select @pc_index = @c_index + 1
 	  select @c_index = CharIndex(',', @singlerow, @pc_index)
         select @c_readlen = @c_index - @pc_index
         select @singlecol = case when isnumeric(@singlecol) = 1 then (dbo.fnDBTranslate(N'0', @singlecol, @singlecol)) else (@singlecol) end
         select @@altercmd = 'alter table #datatable add [' + @singlecol + '] varchar(50)'
         execute sp_executesql @@altercmd
         select @@columncount = @@columnCount + 1
         if (@@columncount > 1)
         begin
           select @@finalselect = @@finalselect + ','
         end
         select @@finalselect = @@finalselect + '[' + @singlecol + ']'
        end
        select @c_readlen = 1 + @rowlength - @pc_index
        if (@c_readlen > 0)
        begin
          select @singlecol = substring(@singlerow, @pc_index, @c_readlen)
          select @singlecol = case when isnumeric(@singlecol) = 1 then (dbo.fnDBTranslate(N'0', @singlecol, @singlecol)) else (@singlecol) end
          select @@altercmd = 'alter table #datatable add [' + @singlecol + '] varchar(50)'
          execute sp_executesql @@altercmd
          select @@columncount = @@columncount + 1
          if (@@columncount > 1)
          begin
            select @@finalselect = @@finalselect + ','
          end
          select @@finalselect = @@finalselect + '[' + @singlecol + ']'
        end
        select @index = CharIndex(';', @paramxml, @previousindex)
        select @readlen = @index - @previousindex
        while (@readlen > 0)
        begin
          select @singlerow = substring(@paramxml, @previousindex, @readlen)
          select @previousindex = @index + 1
          select @rowlength = len(@singlerow)
          select @pc_index = 0
 	   select @c_index = CharIndex(',', @singlerow, @pc_index)
          select @c_readlen = @c_index - @pc_index
 	   select @@insertcmd = 'insert into #datatable values(0'
          while @c_readlen > 0
          begin
           select @singlecol = substring(@singlerow, @pc_index, @c_readlen)
           select @pc_index = @c_index + 1
 	    select @c_index = CharIndex(',', @singlerow, @pc_index)
           select @c_readlen = @c_index - @pc_index
           select @@insertcmd = @@insertcmd + ',''' + @singlecol + ''''
          end
          select @c_readlen = 1 + @rowlength - @pc_index
          if (@c_readlen > 0)
          begin
            select @singlecol = substring(@singlerow, @pc_index, @c_readlen)
            select @@insertcmd = @@insertcmd + ',''' + @singlecol + ''''
          end
        select @@insertcmd = @@insertcmd + ')'
        execute sp_executesql @@insertcmd
        select @index = CharIndex(';', @paramxml, @previousindex)
        select @readlen = @index - @previousindex
        end
          select @rowlength = DATALENGTH(@paramxml)
          select @readlen = 1 + @rowlength - @previousindex
          select @singlerow = substring(@paramxml, @previousindex, @readlen)
          select @rowlength = len(@singlerow)
          select @pc_index = 0
 	   select @c_index = CharIndex(',', @singlerow, @pc_index)
          select @c_readlen = @c_index - @pc_index
 	   select @@insertcmd = 'insert into #datatable values(0'
          while @c_readlen > 0
          begin
           select @singlecol = substring(@singlerow, @pc_index, @c_readlen)
           select @pc_index = @c_index + 1
 	    select @c_index = CharIndex(',', @singlerow, @pc_index)
           select @c_readlen = @c_index - @pc_index
           select @@insertcmd = @@insertcmd + ',''' + @singlecol + ''''
          end
          select @c_readlen = 1 + @rowlength - @pc_index
          if (@c_readlen > 0)
          begin
            select @singlecol = substring(@singlerow, @pc_index, @c_readlen)
            select @@insertcmd = @@insertcmd + ',''' + @singlecol + ''''
          end
          select @@insertcmd = @@insertcmd + ')'
          execute sp_executesql @@insertcmd
      end
    end
    select @@finalselect = @@finalselect + ' from #datatable'
    execute sp_executesql @@finalselect
  end
