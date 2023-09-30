CREATE TABLE [dbo].[Import_Export_Fields] (
    [Comment]           VARCHAR (100) NULL,
    [Comment_Field_SQL] VARCHAR (500) NULL,
    [ED_Field_Type_Id]  INT           NULL,
    [ExcelDateFormat]   VARCHAR (25)  NULL,
    [Field_Name]        VARCHAR (50)  NOT NULL,
    [Field_Order]       INT           NOT NULL,
    [IE_Type_Id]        INT           NOT NULL,
    [IEField_Id]        INT           NOT NULL,
    [Is_Text]           TINYINT       NULL,
    CONSTRAINT [ImportExport_PK_IEFieldId] PRIMARY KEY CLUSTERED ([IEField_Id] ASC),
    CONSTRAINT [IEFields_FK_IETypes] FOREIGN KEY ([IE_Type_Id]) REFERENCES [dbo].[Import_Export_Types] ([IE_Type_Id])
);

