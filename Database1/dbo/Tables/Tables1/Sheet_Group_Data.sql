CREATE TABLE [dbo].[Sheet_Group_Data] (
    [Sheet_Group_Id] INT NOT NULL,
    [Sheet_Id]       INT NOT NULL,
    CONSTRAINT [SheetGrpData_PK_ShtGrpIdShtId] PRIMARY KEY CLUSTERED ([Sheet_Group_Id] ASC, [Sheet_Id] ASC)
);

