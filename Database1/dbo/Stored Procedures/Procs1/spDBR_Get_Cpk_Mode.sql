Create Procedure dbo.spDBR_Get_Cpk_Mode
@mode_id int
as
--TODO get prompt number
 	 declare @Prompt varchar(50)
  if (@mode_id = 1) 
  begin
 	  	 select @Prompt = dbo.fnDBTranslate(N'0', 38440, 'Cpk Weighted Average')
  end
  else
  begin
 	  	 select @Prompt = dbo.fnDBTranslate(N'0', 38440, 'Cpk By Product')
  end
insert into #sp_name_results select @Prompt
