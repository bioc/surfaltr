#' Split a fasta formatted file.
#'
#' The function splits a fasta formatted file to a defined number of smaller 
#' .fasta files for further processing.
#'
#' @param path_in A path to the .FASTA formatted file that is to be processed.
#' @param path_out A path where the resulting .FASTA formatted files should be 
#' stored. The path should also contain the prefix name of the fasta files on 
#' which _n (integer from 1 to number of fasta files generated) will be appended
#' along with the extension ".fa"
#' @param num_seq Integer defining the number of sequences to be in each 
#' resulting .fasta file. Defaults to 20000.
#' @param trim Logical, should the sequences be trimmed to 4000 amino acids 
#' to bypass the CBS server restrictions. Defaults to FALSE.
#' @param trunc Integer, truncate the sequences to this length. First 1:trunc 
#' amino acids will be kept.
#' @param id Logical, should the protein id's be returned. Defaults to FALSE.
#'
#' @return if id = FALSE, A Character vector of the paths to the resulting 
#' .FASTA formatted files.
#'
#' if id = TRUE, A list with two elements:
#' \describe{
#' \item{id}{Character, protein identifiers.}
#' \item{file_list}{Character, paths to the resulting .FASTA formatted files.}
#'   }
#'
#' @import seqinr


split_fasta <- function(path_in,
                path_out,
                num_seq = 20000,
                trim = FALSE,
                trunc = NULL,
                id = FALSE) {
    if (!file.exists(path_in)) {
        stop("cannot find file in the specified path_in")
    }
    if (missing(num_seq)) {
        num_seq <- 20000
    }
    if (length(num_seq) > 1) {
        num_seq <- 20000
        warning("num_seq should be of length 1, setting to default: 
                num_seq = 20000")
    }
    if (!is.numeric(num_seq)) {
        num_seq <- as.numeric(num_seq)
        warning("num_seq is not numeric, converting using 'as.numeric'")
    }
    if (is.na(num_seq)) {
        num_seq <- 20000
        warning("num_seq was set to NA, setting to default: num_seq = 20000")
    }
    if (is.numeric(num_seq)) {
        num_seq <- floor(num_seq)
    }
    if (!missing(trunc)) {
        if (length(trunc) > 1) {
            stop("trunc should be of length 1.")
        }
        if (!is.numeric(trunc)) {
            stop("trunc is not numeric.")
        }
        if (is.na(trunc)) {
            stop("trunc was set to NA.")
        }
        if (is.numeric(trunc)) {
            trunc <- floor(trunc)
        }
        if (trunc < 0) {
            stop("trunc was set to a negative number.")
        }
        if (trunc == 0) {
            trunc <- 1000000L
        }
    }
    if (missing(trim)) {
        trim <- FALSE
    }
    if (length(trim) > 1) {
        trim <- FALSE
        warning("trim should be of length 1, setting to default: trim = FALSE")
    }
    if (!is.logical(trim)) {
        trim <- as.logical(trim)
        warning("trim is not logical, converting using 'as.logical'")
    }
    if (is.na(trim)) {
        trim <- FALSE
        warning("trim was set to NA, setting to default: trim = FALSE")
    }
    if (missing(id)) {
        id <- FALSE
    }
    if (length(id) > 1) {
        id <- FALSE
        warning("id should be of length 1, setting to default: id = FALSE")
    }
    if (!is.logical(id)) {
        id <- as.logical(id)
        warning("id is not logical, converting using 'as.logical'")
    }
    if (is.na(id)) {
        id <- FALSE
        warning("id was set to NA, setting to default: id = FALSE")
    }
    temp_file <- seqinr::read.fasta(file = path_in, seqtype = "AA")
    name <- names(temp_file)
    if (length(name) != length(unique(name))) {
        stop("There are duplicated sequence names. Please change them so all 
             are unique")
    }
    if (!all(name == make.names(name))) {
        warning("Sequence names contain special characters, this can cause 
                problems in downstream functions.")
    }
    if (!missing(trunc)) {
        temp_file <- lapply(temp_file, function(x) {
            len <- length(x)
            if (len > trunc) {
                out <- x[seq_along(trunc)]
            } else {
                out <- x
            }
            return(out)
        })
    }
    if (trim == TRUE && missing(trunc)) {
        temp_file <- lapply(temp_file, function(x) {
            len <- length(x)
            if (len > 4000) {
                out <- x[seq_along(4000)]
            } else {
                out <- x
            }
            return(out)
        })
    }
    len <- length(temp_file)
    splt <- num_seq
    pam <- ((seq(len) - 1) %/% splt) + 1
    m_split <- split(temp_file, pam)
    file_list <- vector("character", length(m_split))
    for (i in seq_along(m_split)) {
        seqinr::write.fasta(
            sequences = m_split[[i]], names = names(m_split[[i]]),
            file.out = paste(path_out, i, ".fa", sep = "")
        )
        file_list[i] <- paste(path_out, i, ".fa", sep = "")
    }
    if (id) {
        return(list(
            id = name,
            file_list = file_list
        ))
    } else {
        return(file_list)
    }
}
