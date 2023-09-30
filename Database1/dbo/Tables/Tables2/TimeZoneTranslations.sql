CREATE TABLE [dbo].[TimeZoneTranslations] (
    [EndTime]         DATETIME      NULL,
    [StartTime]       DATETIME      NULL,
    [TimeZone]        VARCHAR (200) NULL,
    [UTCBias]         INT           NULL,
    [UTCEndTime]      DATETIME      NULL,
    [UTCStartTime]    DATETIME      NULL,
    [TimeZoneTransId] BIGINT        IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [TimeZoneTranslations_PK_Id] PRIMARY KEY NONCLUSTERED ([TimeZoneTransId] ASC)
);


GO
CREATE CLUSTERED INDEX [CL_TimeZoneTranslations_KS1]
    ON [dbo].[TimeZoneTranslations]([TimeZone] ASC, [UTCStartTime] ASC, [UTCEndTime] ASC) WITH (FILLFACTOR = 100);


GO
CREATE NONCLUSTERED INDEX [TimeZoneTranslations_IDX_TZStartUEndU]
    ON [dbo].[TimeZoneTranslations]([TimeZone] ASC, [UTCStartTime] ASC, [UTCEndTime] ASC);


GO
CREATE NONCLUSTERED INDEX [TimeZoneTranslations_IDX_TZStartEnd]
    ON [dbo].[TimeZoneTranslations]([TimeZone] ASC, [StartTime] ASC, [EndTime] ASC);

