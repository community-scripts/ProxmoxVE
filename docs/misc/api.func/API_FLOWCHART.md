# api.func Execution Flowchart

## Main API Communication Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        API Communication Initialization                        │
│  Entry point when api.func functions are called by installation scripts        │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Prerequisites Check                                      │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Prerequisites Validation                                │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Check curl    │    │   Check         │    │   Check             │ │ │
│  │  │   Availability  │    │   Diagnostics   │    │   Random UUID       │ │ │
│  │  │                 │    │   Setting       │    │                     │ │
│  │  │ • command -v    │    │ • DIAGNOSTICS   │    │ • RANDOM_UUID       │ │
│  │  │   curl          │    │   = "yes"       │    │   not empty         │ │
│  │  │ • Return if     │    │ • Return if     │    │ • Return if         │ │
│  │  │   not found     │    │   disabled      │    │   not set          │ │
│  │  │                 │    │                 │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Data Collection                                          │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    System Information Gathering                            │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Get PVE       │    │   Collect       │    │   Prepare JSON      │ │ │
│  │  │   Version        │    │   Environment   │    │   Payload           │ │
│  │  │                 │    │   Variables     │    │                     │ │
│  │  │ • pveversion    │    │ • CT_TYPE       │    │ • Create JSON       │ │
│  │  │   command       │    │ • DISK_SIZE     │    │   structure         │ │
│  │  │ • Parse version │    │ • CORE_COUNT    │    │ • Include all       │ │
│  │  │ • Extract       │    │ • RAM_SIZE      │    │   variables         │ │
│  │  │   major.minor  │    │ • var_os        │    │ • Format for API    │ │
│  │  │                 │    │ • var_version   │    │                     │ │
│  │  │                 │    │ • NSAPP        │    │                     │ │
│  │  │                 │    │ • METHOD       │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        API Request Execution                                   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    HTTP Request Processing                                 │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Prepare       │    │   Execute       │    │   Handle            │ │ │
│  │  │   Request        │    │   HTTP Request  │    │   Response          │ │
│  │  │                 │    │                 │    │                     │ │
│  │  │ • Set API URL   │    │ • curl -s -w    │    │ • Capture HTTP      │ │
│  │  │ • Set headers   │    │   "%{http_code}" │    │   status code      │ │
│  │  │ • Set payload   │    │ • POST request  │    │ • Store response    │ │
│  │  │ • Content-Type  │    │ • JSON data     │    │ • Handle errors     │ │
│  │  │   application/  │    │ • Follow        │    │   gracefully        │ │
│  │  │   json          │    │   redirects     │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## LXC API Reporting Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        POST_TO_API() Flow                                     │
│  Send LXC container installation data to API                                  │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        LXC Data Preparation                                   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    LXC-Specific Data Collection                           │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Set LXC       │    │   Include LXC   │    │   Set Status        │ │ │
│  │  │   Type           │    │   Variables     │    │   Information        │ │
│  │  │                 │    │                 │    │                     │ │
│  │  │ • ct_type: 1    │    │ • DISK_SIZE     │    │ • status:           │ │
│  │  │ • type: "lxc"   │    │ • CORE_COUNT    │    │   "installing"      │ │
│  │  │ • Include all   │    │ • RAM_SIZE      │    │ • Include all       │ │
│  │  │   LXC data      │    │ • var_os        │    │   tracking data     │ │
│  │  │                 │    │ • var_version   │    │                     │ │
│  │  │                 │    │ • DISABLEIP6    │    │                     │ │
│  │  │                 │    │ • NSAPP         │    │                     │ │
│  │  │                 │    │ • METHOD        │    │                     │ │
│  │  │                 │    │ • pve_version   │    │                     │ │
│  │  │                 │    │ • random_id     │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        JSON Payload Creation                                  │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    JSON Structure Generation                               │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Create JSON   │    │   Validate       │    │   Format for        │ │ │
│  │  │   Structure      │    │   Data           │    │   API Request       │ │
│  │  │                 │    │                 │    │                     │ │
│  │  │ • Use heredoc   │    │ • Check all     │    │ • Ensure proper     │ │
│  │  │   syntax        │    │   variables      │    │   JSON format       │ │
│  │  │ • Include all   │    │   are set       │    │ • Escape special    │ │
│  │  │   required      │    │ • Validate      │    │   characters        │ │
│  │  │   fields        │    │   data types    │    │ • Set content       │ │
│  │  │ • Format        │    │ • Handle        │    │   type              │ │
│  │  │   properly      │    │   missing       │    │                     │ │
│  │  │                 │    │   values        │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## VM API Reporting Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        POST_TO_API_VM() Flow                                  │
│  Send VM installation data to API                                            │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        VM Data Preparation                                    │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    VM-Specific Data Collection                             │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Check         │    │   Set VM        │    │   Process Disk      │ │ │
│  │  │   Diagnostics   │    │   Type          │    │   Size              │ │
│  │  │   File          │    │                 │    │                     │ │
│  │  │                 │    │ • ct_type: 2   │    │ • Remove 'G'        │ │
│  │  │ • Check file    │    │ • type: "vm"    │    │   suffix            │ │
│  │  │   existence     │    │ • Include all   │    │ • Convert to        │ │
│  │  │ • Read          │    │   VM data       │    │   numeric value      │ │
│  │  │   DIAGNOSTICS   │    │                 │    │ • Store in          │ │
│  │  │   setting       │    │                 │    │   DISK_SIZE_API    │ │
│  │  │ • Parse value   │    │                 │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        VM JSON Payload Creation                              │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    VM-Specific JSON Structure                              │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Include VM    │    │   Set VM        │    │   Format VM         │ │ │
│  │  │   Variables      │    │   Status         │    │   Data for API      │ │
│  │  │                 │    │                 │    │                     │ │
│  │  │ • DISK_SIZE_API │    │ • status:       │    │ • Ensure proper     │ │
│  │  │ • CORE_COUNT    │    │   "installing"  │    │   JSON format       │ │
│  │  │ • RAM_SIZE      │    │ • Include all   │    │ • Handle VM-        │ │
│  │  │ • var_os        │    │   tracking      │    │   specific data     │ │
│  │  │ • var_version   │    │   information   │    │ • Set appropriate   │ │
│  │  │ • NSAPP         │    │                 │    │   content type      │ │
│  │  │ • METHOD        │    │                 │    │                     │ │
│  │  │ • pve_version   │    │                 │    │                     │ │
│  │  │ • random_id     │    │                 │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Status Update Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        POST_UPDATE_TO_API() Flow                              │
│  Send installation completion status to API                                  │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Update Prevention Check                                │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Duplicate Update Prevention                             │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Check         │    │   Set Flag      │    │   Return Early      │ │ │
│  │  │   POST_UPDATE_  │    │   if First      │    │   if Already        │ │
│  │  │   DONE          │    │   Update        │    │   Updated           │ │
│  │  │                 │    │                 │    │                     │ │
│  │  │ • Check if      │    │ • Set           │    │ • Return 0          │ │
│  │  │   already       │    │   POST_UPDATE_  │    │ • Skip API call    │ │
│  │  │   updated       │    │   DONE=true     │    │ • Prevent          │ │
│  │  │ • Prevent       │    │ • Continue      │    │   duplicate        │ │
│  │  │   duplicate     │    │   with update   │    │   requests         │ │
│  │  │   requests      │    │                 │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Status and Error Processing                            │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Status Determination                                     │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Determine     │    │   Get Error     │    │   Prepare Status    │ │ │
│  │  │   Status         │    │   Description   │    │   Data              │ │
│  │  │                 │    │                 │    │                     │ │
│  │  │ • status:       │    │ • Call          │    │ • Include status    │ │
│  │  │   "success" or  │    │   get_error_    │    │ • Include error     │ │
│  │  │   "failed"      │    │   description() │    │   description       │ │
│  │  │ • Set exit      │    │ • Get human-    │    │ • Include random    │ │
│  │  │   code based    │    │   readable      │    │   ID for tracking   │ │
│  │  │   on status     │    │   error message │    │                     │ │
│  │  │ • Default to    │    │ • Handle        │    │                     │ │
│  │  │   error if      │    │   unknown       │    │                     │ │
│  │  │   not set      │    │   errors         │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Status Update API Request                              │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Status Update Payload Creation                          │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Create        │    │   Send Status    │    │   Mark Update       │ │ │
│  │  │   Status JSON    │    │   Update         │    │   Complete          │ │
│  │  │                 │    │                 │    │                     │ │
│  │  │ • Include       │    │ • POST to        │    │ • Set              │ │
│  │  │   status        │    │   updatestatus   │    │   POST_UPDATE_     │ │
│  │  │ • Include       │    │   endpoint       │    │   DONE=true        │ │
│  │  │   error         │    │ • Include JSON   │    │ • Prevent further  │ │
│  │  │   description   │    │   payload        │    │   updates          │ │
│  │  │ • Include       │    │ • Handle         │    │ • Complete         │ │
│  │  │   random_id     │    │   response       │    │   process          │ │
│  │  │                 │    │   gracefully     │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Error Description Flow

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        GET_ERROR_DESCRIPTION() Flow                           │
│  Convert numeric exit codes to human-readable explanations                    │
└─────────────────────┬───────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Error Code Classification                              │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Error Code Categories                                  │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   General       │    │   Network        │    │   LXC-Specific      │ │ │
│  │  │   System        │    │   Errors         │    │   Errors            │ │
│  │  │   Errors        │    │                 │    │                     │ │
│  │  │                 │    │ • 18: Connection│    │ • 100-101: LXC      │ │
│  │  │ • 0-9: Basic    │    │   failed         │    │   install errors    │ │
│  │  │   errors        │    │ • 22: Invalid    │    │ • 200-209: LXC      │ │
│  │  │ • 126-128:      │    │   argument       │    │   creation errors   │ │
│  │  │   Command       │    │ • 28: No space   │    │                     │ │
│  │  │   errors        │    │ • 35: Timeout    │    │                     │ │
│  │  │ • 129-143:      │    │ • 56: TLS error  │    │                     │ │
│  │  │   Signal        │    │ • 60: SSL cert   │    │                     │ │
│  │  │   errors        │    │   error          │    │                     │ │
│  │  │ • 152: Resource │    │                 │    │                     │ │
│  │  │   limit         │    │                 │    │                     │ │
│  │  │ • 255: Unknown  │    │                 │    │                     │ │
│  │  │   critical      │    │                 │    │                     │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Error Message Return                                   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Error Message Formatting                               │ │
│  │                                                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────┐ │ │
│  │  │   Match Error   │    │   Return        │    │   Default Case       │ │ │
│  │  │   Code          │    │   Description   │    │                     │ │
│  │  │                 │    │                 │    │                     │ │
│  │  │ • Use case      │    │ • Return        │    │ • Return "Unknown   │ │
│  │  │   statement     │    │   human-        │    │   error code        │ │
│  │  │ • Match         │    │   readable      │    │   (exit_code)"      │ │
│  │  │   specific      │    │   message       │    │ • Handle            │ │
│  │  │   codes         │    │ • Include       │    │   unrecognized      │ │
│  │  │ • Handle        │    │   context       │    │   codes             │ │
│  │  │   ranges        │    │   information   │    │ • Provide fallback  │ │
│  │  │                 │    │                 │    │   message           │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Integration Points

### With Installation Scripts
- **build.func**: Sends LXC installation data
- **vm-core.func**: Sends VM installation data
- **install.func**: Reports installation status
- **alpine-install.func**: Reports Alpine installation data

### With Error Handling
- **error_handler.func**: Provides error explanations
- **core.func**: Uses error descriptions in silent execution
- **Diagnostic reporting**: Tracks error patterns

### External Dependencies
- **curl**: HTTP client for API communication
- **Community Scripts API**: External API endpoint
- **Network connectivity**: Required for API communication
