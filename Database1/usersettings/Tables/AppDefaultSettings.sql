CREATE TABLE [usersettings].[AppDefaultSettings] (
    [id]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [application_id]   INT            NOT NULL,
    [view_name]        VARCHAR (50)   NOT NULL,
    [data]             NVARCHAR (MAX) NULL,
    [last_modified_on] DATETIME       NULL,
    [last_modified_by] VARCHAR (255)  NOT NULL,
    CONSTRAINT [PK_AppDefaultSettings] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UK_AppDefaultSettings_App_Id_view_name_last_modified_by] UNIQUE NONCLUSTERED ([application_id] ASC, [view_name] ASC, [last_modified_by] ASC)
);

