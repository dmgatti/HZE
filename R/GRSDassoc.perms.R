#' @title Permutation analysis for HZE.
#' @author Elijah F. Edmondson <elijah.edmondson@gmail.com>
#' @export

GRSDassoc.perms = function(perms, chr = 1:19, Xchr = TRUE,
                           pheno, pheno.col = "Albino", probs, K, addcovar,
                           markers, snp.file, outdir = "~/Desktop/files",
                           tx = "Unirradiated") {
        begin <- Sys.time()
        begin

        samples = intersect(rownames(pheno), rownames(probs))
        samples = intersect(samples, rownames(addcovar))
        samples = intersect(samples, rownames(K[[1]]))
        stopifnot(length(samples) > 0)

        pheno = pheno[samples,,drop = FALSE]
        addcovar = addcovar[samples,,drop = FALSE]
        probs = probs[samples,,,drop = FALSE]

        # DEFINE TRAIT #

        file.prefix = paste(tx, pheno.col, sep = "_")

        plot.title = paste(tx, pheno.col, sep = " ")
        print(plot.title)

        trait = pheno[,pheno.col]

        # LOGISTIC REGRESSION MODEL #
        for(i in 1:length(K)) {
                K[[i]] = K[[i]][samples, samples]
        } # for(i)

        chrs = c(1:19, "X")
        data = vector("list", length(chrs))
        names(data) = chrs
        for(i in 1:length(chrs)) {

                rng = which(markers[,2] == chrs[i])
                data[[i]] = list(probs = probs[,,rng], K = K[[i]],
                                 markers = markers[rng,])

        } # for(i)

        rm(probs, K, markers)

        setwd(outdir)

        ##
        result = vector("list", length(data))
        names(result) = names(data)
        females = which(pheno$sex == "0")
        males = which(pheno$sex == "1")

        permutations = matrix(1, nrow = perms, ncol = 2, dimnames = list(1:perms, c("A", "X")))

        for(p in 1:perms) {
                print(p)
                new.order = rep(0, length(trait))
                new.order[females] = sample(females)
                new.order[males] = sample(males)

                log.perm = trait[new.order]
                trait = log.perm

                phenonew = data.frame(cbind("sex" = pheno$sex, trait))

                min.a.pv = 1

                #for(i in length(chr)) {
                #        result = GRSDbinom(data[[i]], pheno, pheno.col, addcovar, tx)
                #        min.a.pv = min(min.a.pv, min(result$pv))
                #} #for(i)

                result = GRSDbinom(data[[chr]], pheno = phenonew, pheno.col = "trait", addcovar, tx)
                min.a.pv = min(min.a.pv, min(result$pv))

                min.x.pv = 1

                if(Xchr) {
                        result = GRSDbinom.xchr(data[["X"]], pheno, pheno.col, addcovar, tx)
                        min.x.pv = min(result$pv)
                }
                # Save the minimum p-values.
                permutations[p,] = c(-log10(min.a.pv), -log10(min.x.pv))


        }

        save(permutations, file.prefix, file = paste0(file.prefix, "_perms.Rdata"))
        return(permutations)
        print(paste(round(difftime(Sys.time(), begin, units = 'hours'), digits = 2),
                    "hours elapsed during analysis"))

}