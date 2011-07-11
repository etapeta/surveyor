Logger # to ensure class is loaded

class Logger
  def mark(*args)
    info('>' * 80)
    if args.size == 2
      info(args[0].to_s.upcase + ': ' + args[1].inspect)
    else
      info(*args)
    end
    info('>' * 80)
  end
end
