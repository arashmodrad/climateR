whatOS = function(){
  sysinf <- Sys.info()
  if (!is.null(sysinf)){
    os <- sysinf['sysname']
    if (os == 'Darwin')
      os <- "osx"
  } else { ## mystery machine
    os <- .Platform$OS.type
    if (grepl("^darwin", R.version$os))
      os <- "osx"
    if (grepl("linux-gnu", R.version$os))
      os <- "linux"
  }
  tolower(os)
}

build_file = function(file){
  if (whatOS() == "windows") {
    paste0(Sys.getenv("UserProfile"), "\\", paste0(".", file))
  } else {
    paste0(Sys.getenv("HOME"), "/" , paste0(".", file))
  }
}

#' @title Get a default dodsrc file path
#' @description Get a default dodsrc file path
#' @return A character vector containing the default netrc file path
#' @examples
#' getDodsrcPath()
#' @export
#' @family netrc

getDodsrcPath <- function() { build_file("dodsrc") }

#' @title Get the default netrc file path
#' @description Get a default netrc file path
#' @return A character vector containing the default netrc file path
#' @examples
#' getNetrcPath()
#' @export
#' @family netrc

getNetrcPath <- function() { build_file("netrc") }

#' @title Write netrc file
#' @description Write a netrc file that is valid for accessing urs.earthdata.nasa.gov
#' @details
#' The database is accessed with the user's credentials.
#' A netrc file storing login and password information is required.
#' See \href{https://urs.earthdata.nasa.gov/}{here}. Once set up you must do the following
#' (1) Login to EarthData (2) Go to Applications > Authorized Apps (3) If NASA GESDISC DATA ARCHIVE is not in the Approved Applications list, select APPROVE MORE APPLICATIONS
#' (4) Find NASA GESDISC DATA ARCHIVE and click AUTHORIZE
#' for instruction on how to register and set DataSpace credential.
#' @param login A character. Email address used for logging in on earthdata
#' @param password A character. Password associated with the login.
#' @param machine the machine you are logging into
#' @param netrcFile A character. A path to where the netrc file should be written.
#' By default will go to your home directory, which is advised
#' @param overwrite A logical. overwrite the existing netrc file?
#' @return A character vector containing the netrc file path
#' @family netrc
#' @examples
#' \dontrun{
#' writeNetrc(
#'   login = "XXX@email.com",
#'   password = "yourSecretPassword"
#' )
#' }
#' @export

writeNetrc <- function(login,
                       password,
                       machine = 'urs.earthdata.nasa.gov',
                       netrcFile =  getNetrcPath(),
                       overwrite = FALSE) {
  
  if(missing(login) | missing(password)){
    stop("Login/Password is missing. If you dont have an account please registar at:\nhttps://urs.earthdata.nasa.gov/users/new",
         call. = FALSE)
  }
  
  if (file.exists(netrcFile) && !overwrite) {
    stop("'", netrcFile, "' already exists. Set `overwrite=TRUE`
         if you'd like to overwrite.",
         call. = FALSE
    )
  }
  
  string <- paste(
    "\nmachine ", machine,
    "login", login,
    "password", password
  )
  
  # create a netrc file
  write(string,  path.expand(netrcFile), append=TRUE)
  
  # set the owner-only permission
  Sys.chmod(netrcFile, mode = "600")
  
  netrcFile
}

#' @title Check netrc file
#' @description Check that there is a netrc file with a valid
#' entry for urs.earthdata.nasa.gov.
#' @param netrcFile A character. File path to netrc file to check.
#' @param machine the machine you are logging into
#' @return logical
#' @family netrc
#' @export

checkNetrc <- function(netrcFile = getNetrcPath(), machine = "urs.earthdata.nasa.gov" ) {
  
  if (!file.exists(netrcFile)) { return(FALSE) }
  
  lines <- gsub("http.*//", "", readLines(netrcFile))
  
  return(any(grepl(machine, lines)))
}


#' @title Write dodsrc file
#' @description Write a dodsrc file that is valid for a netrc file
#' @param netrcFile A character. A path to where the netrc file should be.
#' @param dodsrcFile The path to the dodsrc file you want to write
#' By default will go to your home directory, which is advised
#' @return A character vector containing the netrc file path
#' @family netrc
#' @export

writeDodsrc = function(netrcFile = getNetrcPath(), dodsrcFile = ".dodsrc"){
  
  unlink(dodsrcFile)
  dir = dirname(dodsrcFile)
  
  string <- paste0(
    'USE_CACHE=0\n',
    'MAX_CACHE_SIZE=20\n',
    'MAX_CACHED_OBJ=5\n',
    'IGNORE_EXPIRES=0\n',
    'DEFAULT_EXPIRES=86400\n',
    'ALWAYS_VALIDATE=0\n',
    'DEFLATE=0\n',
    'VALIDATE_SSL=1\n',
    paste0('HTTP.COOKIEJAR=', dir, '/.urs_cookies\n'),
    paste0('HTTP.NETRC=', netrcFile))

  # create a netrc file
  write(string, path.expand(dodsrcFile))
  
  # set the owner-only permission
  Sys.chmod(dodsrcFile, mode = "600")
  
  dodsrcFile
  
}

#' @title Check dodsrc file
#' @description Check that there is a netrc file with a valid entry for urs.earthdata.nasa.gov.
#' @param dodsrcFile File path to dodsrc file to check.
#' @param netrcFile  File path to netrc file to check.
#' @return logical
#' @family netrc
#' @export

checkDodsrc <- function(dodsrcFile = getDodsrcPath(),
                        netrcFile = getNetrcPath()) {
  
  if (!file.exists(netrcFile))  { return(FALSE) }
  if (!file.exists(dodsrcFile)) { return(FALSE) }
  
  lines <- gsub("http.*//", "", readLines(dodsrcFile))
  
  return(any(grepl(netrcFile, lines)))
}

check_rc_files = function(dodsrcFile = getDodsrcPath(),
                          netrcFile  = getNetrcPath()){
  if(!checkDodsrc(dodsrcFile, netrcFile)){
    if(checkNetrc(netrcFile)){
      message("Found Netrc file. Writing dodsrs file to: ", getDodsrcPath())
      writeDodsrc(netrcFile, dodsrcFile)
    } else{
      stop("Netrc file not found. Please run writeNetrc() with earth data credentials.")
    }
  }
}


