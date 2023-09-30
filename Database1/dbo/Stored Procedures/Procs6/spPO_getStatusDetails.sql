
CREATE PROCEDURE dbo.spPO_getStatusDetails
@StatusSet			nvarchar(max)	= null	-- Set of status ID as a string
,@StatusName nvarchar(max) = null
AS



SELECT @StatusSet = ltrim(rtrim(@StatusSet))
SELECT @StatusName = ltrim(rtrim(@StatusName))
    If(@StatusSet = '') Select @StatusSet = null
    If(@StatusName = '') select @StatusName = null

Declare @StatusDetails Table(
    StatusId int Not Null,
    StatusDescLocal nvarchar(400) Null, -- Max Allowed from PA admin is 50 characters
    StatusDesc nvarchar(400) Null,
    AllowEdit int Null,
    Colour nvarchar(200) Null,
    Movable int Null,
    StatusGroup nvarchar(400) Null,
    StatusSortOrder int Null
)





DECLARE @SQL nvarchar(max)
SELECT @SQL =''
SELECT @SQL='
;WITH TmpPOs (StatusId, StatusDescLocal, StatusDesc, AllowEdit, Colour, Movable, StatusGroup, StatusSortOrder)
            as (SELECT ppst.PP_Status_Id, ppst.PP_Status_Desc_Local, ppst.PP_Status_Desc, ppst.Allow_Edit, Null, ppst.Movable, ppst.Status_Group, ppst.Status_Order
          FROM  Production_Plan_Statuses ppst with (nolock)
WHERE 1=1
'
    IF(@StatusName is not null)  -- searching for Status name.
        BEGIN
            select @SQL = @SQL + ' AND PP_Status_Desc like ''%' +  @StatusName+'%'''
        end

SELECT @SQL = @SQL+Case when @StatusSet is null then '' else ' AND PP_Status_Id in ('+@StatusSet+')' end

SELECT @SQL = @SQL+ ')'
SELECT @SQL = @SQL+
              'Select
                       *  from TmpPOs;'



INSERT INTO @StatusDetails(StatusId, StatusDescLocal, StatusDesc, AllowEdit, Colour, Movable, StatusGroup, StatusSortOrder)
    EXEC(@SQL)


    -- Colours we can get from "select * from Colors"
    -- Update the colour codes here with hardcoded values for now. This will move on to the colour schemes later
-- First setting everything to black colour
    Update @StatusDetails set Colour = '#000000' where StatusId is not null

    Update @StatusDetails set Colour = '#79ce1b' where StatusId = 3 -- Colour for Active[3] = #79ce1b

    Update @StatusDetails set Colour = '#a3b5bf' where StatusId in (-2,4)
    -- Colour for COMPLETE[4] = #a3b5bf
    -- Colour for CANCELLED[-2] = #a3b5bf

    Update @StatusDetails set Colour = '#fec600' where StatusId = 1     -- Colour for Pending[1] = #fec600

    Update @StatusDetails set Colour = '#ff8b3a' where StatusId = 7 -- Colour for PLANNING[7] = #ff8b3a

    Update @StatusDetails set Colour = '#f34336' where StatusId in (-1,5,6)
    -- Colour for OVERPRODUCED[5] = #f34336
    -- Colour for UNDERPRODUCED[6] = #f34336
    -- Colour for ERROR[-1] = #f34336

    Update @StatusDetails set Colour = '#45ace5' where StatusId = 2  -- Colour for NEXT[2] = #45ace5









Select * from @StatusDetails



